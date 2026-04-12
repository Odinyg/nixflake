# Compression helpers for zsh.
# Source this file to get compress, compress_zip, and extract.

compress() {
	local target="${1%/}"
	tar -czf "${target}.tar.gz" "$target"
}

compress_zip() {
	local target="${1%/}"
	zip -r "${target}.zip" "$target"
}

extract() {
	case "$1" in
		*.tar.gz|*.tgz)
			tar -xf "$1"
			;;
		*.tar.bz2)
			tar -xf "$1"
			;;
		*.tar.xz)
			tar -xf "$1"
			;;
		*.zip)
			unzip "$1"
			;;
		*.gz)
			gunzip "$1"
			;;
		*.bz2)
			bunzip2 "$1"
			;;
		*.xz)
			unxz "$1"
			;;
		*)
			echo "Unknown archive format: $1" >&2
			return 1
			;;
	esac
}
