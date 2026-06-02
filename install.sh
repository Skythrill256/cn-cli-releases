#!/usr/bin/env sh
set -eu

base_url="${CN_RELEASE_BASE_URL:-https://skythrill256.github.io/cn-cli-releases}"
install_dir="${CN_INSTALL_DIR:-$HOME/.local/bin}"

command -v curl >/dev/null 2>&1 || {
  echo "curl is required to install CN" >&2
  exit 1
}

command -v gzip >/dev/null 2>&1 || {
  echo "gzip is required to install CN" >&2
  exit 1
}

os="$(uname -s)"
machine="$(uname -m)"

case "$os" in
  Darwin)
    case "$machine" in
      arm64) platform="darwin-arm64" ;;
      x86_64) platform="darwin-x64" ;;
      *)
        echo "Unsupported macOS architecture: $machine" >&2
        exit 1
        ;;
    esac
    ;;
  Linux)
    case "$machine" in
      aarch64 | arm64) arch="arm64" ;;
      x86_64 | amd64) arch="x64" ;;
      *)
        echo "Unsupported Linux architecture: $machine" >&2
        exit 1
        ;;
    esac

    abi=""
    if command -v ldd >/dev/null 2>&1 && ldd --version 2>&1 | grep -qi musl; then
      abi="-musl"
    fi
    platform="linux-$arch$abi"
    ;;
  *)
    echo "Unsupported OS: $os" >&2
    exit 1
    ;;
esac

version="${CN_VERSION:-$(curl -fsSL "$base_url/latest")}"
mkdir -p "$install_dir"

tmp_dir="${TMPDIR:-/tmp}"
tmp_file="$tmp_dir/cn.$$.gz"
trap 'rm -f "$tmp_file"' EXIT INT TERM

curl -fsSL "$base_url/$version/$platform/cn.gz" -o "$tmp_file"
gzip -dc "$tmp_file" > "$install_dir/cn"
chmod +x "$install_dir/cn"

case ":$PATH:" in
  *":$install_dir:"*) ;;
  *)
    shell_name="$(basename "${SHELL:-sh}")"
    case "$shell_name" in
      zsh) rc_file="${ZDOTDIR:-$HOME}/.zshrc" ;;
      bash) rc_file="$HOME/.bashrc" ;;
      *) rc_file="$HOME/.profile" ;;
    esac

    path_line="export PATH=\"$install_dir:\$PATH\""
    if [ "$install_dir" = "$HOME/.local/bin" ]; then
      path_line='export PATH="$HOME/.local/bin:$PATH"'
    fi

    if [ ! -f "$rc_file" ] || ! grep -F "$install_dir" "$rc_file" >/dev/null 2>&1; then
      printf '\n%s\n' "$path_line" >> "$rc_file"
      echo "Added $install_dir to PATH in $rc_file"
    fi
    ;;
esac

"$install_dir/cn" --version
