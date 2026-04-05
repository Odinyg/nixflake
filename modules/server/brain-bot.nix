{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.server.brain-bot;

  python = pkgs.python3.withPackages (ps: [
    ps.matrix-nio
    ps.aiohttp
  ]);

  botScript = pkgs.writeText "brain-bot.py" ''
    import asyncio
    import json
    import os
    import sys
    import logging

    import aiohttp
    from nio import AsyncClient, MatrixRoom, RoomMessageText, InviteMemberEvent

    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
    log = logging.getLogger("brain-bot")

    HOMESERVER = os.environ["BRAIN_BOT_HOMESERVER"]
    USER_ID = os.environ["BRAIN_BOT_USER_ID"]
    ACCESS_TOKEN = os.environ["BRAIN_BOT_ACCESS_TOKEN"]
    OLLAMA_URL = os.environ.get("BRAIN_BOT_OLLAMA_URL", "http://10.10.10.10:11434")
    OLLAMA_MODEL = os.environ.get("BRAIN_BOT_OLLAMA_MODEL", "llama3.1:8b")
    SYSTEM_PROMPT = os.environ.get(
        "BRAIN_BOT_SYSTEM_PROMPT",
        "You are a helpful assistant running on a homelab Matrix server. Be concise and useful.",
    )

    # Track rooms we've synced so we don't respond to old messages
    synced_rooms: set[str] = set()


    async def ollama_chat(messages: list[dict]) -> str:
        payload = {
            "model": OLLAMA_MODEL,
            "messages": messages,
            "stream": False,
        }
        async with aiohttp.ClientSession() as session:
            async with session.post(f"{OLLAMA_URL}/api/chat", json=payload) as resp:
                if resp.status != 200:
                    text = await resp.text()
                    return f"Error from Ollama ({resp.status}): {text[:500]}"
                data = await resp.json()
                return data["message"]["content"]


    async def on_message(room: MatrixRoom, event: RoomMessageText, client: AsyncClient):
        # Ignore our own messages
        if event.sender == client.user_id:
            return

        # Ignore messages from before we joined / initial sync
        if room.room_id not in synced_rooms:
            return

        user_message = event.body
        log.info(f"Message in {room.display_name} from {event.sender}: {user_message[:100]}")

        messages = [
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": user_message},
        ]

        try:
            reply = await ollama_chat(messages)
        except Exception as e:
            log.error(f"Ollama error: {e}")
            reply = f"Sorry, I couldn't process that: {e}"

        # Chunk long replies for readability
        max_len = 4000
        chunks = [reply[i : i + max_len] for i in range(0, len(reply), max_len)]
        for chunk in chunks:
            await client.room_send(
                room.room_id,
                message_type="m.room.message",
                content={"msgtype": "m.text", "body": chunk},
            )


    async def on_invite(room: MatrixRoom, event: InviteMemberEvent, client: AsyncClient):
        if event.state_key == client.user_id:
            log.info(f"Invited to {room.room_id}, joining...")
            await client.join(room.room_id)


    async def main():
        client = AsyncClient(HOMESERVER, USER_ID)
        client.access_token = ACCESS_TOKEN

        # Verify credentials
        resp = await client.whoami()
        log.info(f"Logged in as {resp.user_id}")

        # Register callbacks
        client.add_event_callback(lambda room, event: on_message(room, event, client), RoomMessageText)
        client.add_event_callback(lambda room, event: on_invite(room, event, client), InviteMemberEvent)

        # Initial sync — mark all current rooms so we skip old messages
        log.info("Performing initial sync...")
        sync_resp = await client.sync(timeout=10000)
        for room_id in sync_resp.rooms.join:
            synced_rooms.add(room_id)
        log.info(f"Initial sync complete, tracking {len(synced_rooms)} rooms")

        # Continuous sync
        log.info("Listening for messages...")
        await client.sync_forever(timeout=30000, full_state=True)


    if __name__ == "__main__":
        asyncio.run(main())
  '';
in
{
  options.server.brain-bot = {
    enable = lib.mkEnableOption "Brain Bot — AI-powered Matrix chatbot";
    homeserver = lib.mkOption {
      type = lib.types.str;
      default = "http://localhost:6167";
      description = "Matrix homeserver URL";
    };
    userId = lib.mkOption {
      type = lib.types.str;
      default = "@brain:pytt.io";
      description = "Matrix user ID for the bot";
    };
    ollamaUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://10.10.10.10:11434";
      description = "Ollama API URL";
    };
    ollamaModel = lib.mkOption {
      type = lib.types.str;
      default = "llama3.1:8b";
      description = "Ollama model to use for chat";
    };
    systemPrompt = lib.mkOption {
      type = lib.types.str;
      default = "You are a helpful assistant running on a homelab Matrix server. Be concise and useful.";
      description = "System prompt for the LLM";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.brain_bot_access_token = { };

    sops.templates."brain-bot-env".content = ''
      BRAIN_BOT_HOMESERVER=${cfg.homeserver}
      BRAIN_BOT_USER_ID=${cfg.userId}
      BRAIN_BOT_ACCESS_TOKEN=${config.sops.placeholder.brain_bot_access_token}
      BRAIN_BOT_OLLAMA_URL=${cfg.ollamaUrl}
      BRAIN_BOT_OLLAMA_MODEL=${cfg.ollamaModel}
      BRAIN_BOT_SYSTEM_PROMPT=${cfg.systemPrompt}
    '';

    systemd.services.brain-bot = {
      description = "Brain Bot — AI Matrix chatbot";
      after = [ "conduit.service" ];
      requires = [ "conduit.service" ];
      partOf = [ "homelab.target" ];
      wantedBy = [ "homelab.target" ];

      serviceConfig = {
        Type = "simple";
        DynamicUser = true;
        ExecStart = "${python}/bin/python3 ${botScript}";
        EnvironmentFile = config.sops.templates."brain-bot-env".path;
        Restart = "on-failure";
        RestartSec = 10;

        # Sandboxing
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectKernelTunables = true;
        ProtectControlGroups = true;
        RestrictSUIDSGID = true;
      };
    };
  };
}
