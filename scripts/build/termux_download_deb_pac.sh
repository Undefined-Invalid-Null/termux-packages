#!/usr/bin/bash

termux_download_deb_pac() {
	local PACKAGE=$1
	local PACKAGE_ARCH=$2
	local VERSION=$3
	local VERSION_PACMAN=$4

	local PKG_FILE
	if [ "$TERMUX_REPO_PKG_FORMAT" = "debian" ]; then
		PKG_FILE="${PACKAGE}_${VERSION}_${PACKAGE_ARCH}.deb"
	elif [ "$TERMUX_REPO_PKG_FORMAT" = "pacman" ]; then
		PKG_FILE="${PACKAGE}-${VERSION_PACMAN}-${PACKAGE_ARCH}.pkg.tar.xz"
	fi
	PKG_HASH=""

	# 允许从官方仓库下载依赖（包名不同时）
	if [ "$TERMUX_REPO_APP__PACKAGE_NAME" != "$TERMUX_APP_PACKAGE" ]; then
		# 如果是 UIN.Tool 且尝试从官方 com.termux 下载，允许通过
		if [ "$TERMUX_APP_PACKAGE" = "com.UIN.Tool" ] && [ "$TERMUX_REPO_APP__PACKAGE_NAME" = "com.termux" ]; then
			echo "INFO: Allowing dependency download from official repo ($TERMUX_REPO_APP__PACKAGE_NAME) for custom package ($TERMUX_APP_PACKAGE)"
		elif [ "${TERMUX_ALLOW_CROSS_REPO_DOWNLOAD:-false}" = "true" ]; then
			echo "INFO: Cross-repo download allowed via TERMUX_ALLOW_CROSS_REPO_DOWNLOAD"
		else
			echo "Ignoring download of $PKG_FILE since repo package name ($TERMUX_REPO_APP__PACKAGE_NAME) does not equal app package name ($TERMUX_APP_PACKAGE)"
			return 1
		fi
	fi

	for idx in $(seq ${#TERMUX_REPO_URL[@]}); do
		local TERMUX_REPO_NAME=$(echo ${TERMUX_REPO_URL[$idx-1]} | sed -e 's%https://%%g' -e 's%http://%%g' -e 's%/%-%g')
		if [ "$TERMUX_REPO_PKG_FORMAT" = "debian" ]; then
			local PACKAGE_FILE_PATH="${TERMUX_REPO_NAME}-${TERMUX_REPO_DISTRIBUTION[$idx-1]}-${TERMUX_REPO_COMPONENT[$idx-1]}-Packages"
		elif [ "$TERMUX_REPO_PKG_FORMAT" = "pacman" ]; then
			local PACKAGE_FILE_PATH="${TERMUX_REPO_NAME}-json"
		fi
		if [ "${PACKAGE_ARCH}" = 'all' ]; then
			for arch in 'aarch64' 'arm' 'i686' 'x86_64'; do
				if [ -f "${TERMUX_COMMON_CACHEDIR}-${arch}/${PACKAGE_FILE_PATH}" ]; then
					if [ "$TERMUX_REPO_PKG_FORMAT" = "debian" ]; then
						read -rd "\n" PKG_PATH PKG_HASH < <(./scripts/get_hash_from_file.py "${TERMUX_COMMON_CACHEDIR}-${arch}/$PACKAGE_FILE_PATH" "$PACKAGE" "$VERSION")
					elif [ "$TERMUX_REPO_PKG_FORMAT" = "pacman" ]; then
						if [ "$TERMUX_WITHOUT_DEPVERSION_BINDING" = "true" ] || [ $(jq -r '."'$PACKAGE'". "VERSION"' "${TERMUX_COMMON_CACHEDIR}-${arch}/$PACKAGE_FILE_PATH") = "${VERSION_PACMAN}" ]; then
							PKG_HASH=$(jq -r '."'$PACKAGE'". "SHA256SUM"' "${TERMUX_COMMON_CACHEDIR}-${arch}/$PACKAGE_FILE_PATH")
							PKG_PATH=$(jq -r '."'$PACKAGE'". "FILENAME"' "${TERMUX_COMMON_CACHEDIR}-${arch}/$PACKAGE_FILE_PATH")
							PKG_PATH="${arch}/${PKG_PATH}"
						fi
					fi
					if [ -n "$PKG_HASH" ] && [ "$PKG_HASH" != "null" ]; then
						if [ ! "$TERMUX_QUIET_BUILD" = true ]; then
							if [ "$TERMUX_REPO_PKG_FORMAT" = "debian" ]; then
								echo "Found $PACKAGE in ${TERMUX_REPO_URL[$idx-1]}/dists/${TERMUX_REPO_DISTRIBUTION[$idx-1]}"
							elif [ "$TERMUX_REPO_PKG_FORMAT" = "pacman" ]; then
								echo "Found $PACKAGE in ${TERMUX_REPO_URL[$idx-1]}"
							fi
						fi
						break 2
					fi
				fi
			done
		elif [ ! -f "${TERMUX_COMMON_CACHEDIR}-${PACKAGE_ARCH}/${PACKAGE_FILE_PATH}" ] && \
			[ -f "${TERMUX_COMMON_CACHEDIR}-aarch64/${PACKAGE_FILE_PATH}" ]; then
			if [ "$TERMUX_REPO_PKG_FORMAT" = "debian" ]; then
				read -rd "\n" PKG_PATH PKG_HASH < <(./scripts/get_hash_from_file.py "${TERMUX_COMMON_CACHEDIR}-aarch64/$PACKAGE_FILE_PATH" "$PACKAGE" "$VERSION")
			elif [ "$TERMUX_REPO_PKG_FORMAT" = "pacman" ]; then
				if [ "$TERMUX_WITHOUT_DEPVERSION_BINDING" = "true" ] || [ $(jq -r '."'$PACKAGE'". "VERSION"' "${TERMUX_COMMON_CACHEDIR}-aarch64/$PACKAGE_FILE_PATH") = "${VERSION_PACMAN}" ]; then
					PKG_HASH=$(jq -r '."'$PACKAGE'". "SHA256SUM"' "${TERMUX_COMMON_CACHEDIR}-aarch64/$PACKAGE_FILE_PATH")
					PKG_PATH=$(jq -r '."'$PACKAGE'". "FILENAME"' "${TERMUX_COMMON_CACHEDIR}-aarch64/$PACKAGE_FILE_PATH")
					PKG_PATH="aarch64/${PKG_PATH}"
				fi
			fi
			if [ -n "$PKG_HASH" ] && [ "$PKG_HASH" != "null" ]; then
				if [ ! "$TERMUX_QUIET_BUILD" = true ]; then
					if [ "$TERMUX_REPO_PKG_FORMAT" = "debian" ]; then
						echo "Found $PACKAGE in ${TERMUX_REPO_URL[$idx-1]}/dists/${TERMUX_REPO_DISTRIBUTION[$idx-1]}"
					elif [ "$TERMUX_REPO_PKG_FORMAT" = "pacman" ]; then
						echo "Found $PACKAGE in ${TERMUX_REPO_URL[$idx-1]}"
					fi
				fi
				break
			fi
		elif [ -f "${TERMUX_COMMON_CACHEDIR}-${PACKAGE_ARCH}/${PACKAGE_FILE_PATH}" ]; then
			if [ "$TERMUX_REPO_PKG_FORMAT" = "debian" ]; then
				read -rd "\n" PKG_PATH PKG_HASH < <(./scripts/get_hash_from_file.py "${TERMUX_COMMON_CACHEDIR}-${PACKAGE_ARCH}/$PACKAGE_FILE_PATH" "$PACKAGE" "$VERSION")
			elif [ "$TERMUX_REPO_PKG_FORMAT" = "pacman" ]; then
				if [ "$TERMUX_WITHOUT_DEPVERSION_BINDING" = "true" ] || [ $(jq -r '."'$PACKAGE'". "VERSION"' "${TERMUX_COMMON_CACHEDIR}-${PACKAGE_ARCH}/$PACKAGE_FILE_PATH") = "${VERSION_PACMAN}" ]; then
					PKG_HASH=$(jq -r '."'$PACKAGE'". "SHA256SUM"' "${TERMUX_COMMON_CACHEDIR}-${PACKAGE_ARCH}/$PACKAGE_FILE_PATH")
					PKG_PATH=$(jq -r '."'$PACKAGE'". "FILENAME"' "${TERMUX_COMMON_CACHEDIR}-${PACKAGE_ARCH}/$PACKAGE_FILE_PATH")
					PKG_PATH="${PACKAGE_ARCH}/${PKG_PATH}"
				fi
			fi
			if [ -n "$PKG_HASH" ] && [ "$PKG_HASH" != "null" ]; then
				if [ ! "$TERMUX_QUIET_BUILD" = true ]; then
					if [ "$TERMUX_REPO_PKG_FORMAT" = "debian" ]; then
						echo "Found $PACKAGE in ${TERMUX_REPO_URL[$idx-1]}/dists/${TERMUX_REPO_DISTRIBUTION[$idx-1]}"
					elif [ "$TERMUX_REPO_PKG_FORMAT" = "pacman" ]; then
						echo "Found $PACKAGE in ${TERMUX_REPO_URL[$idx-1]}"
					fi
				fi
				break
			fi
		fi
	done

	if [ "$PKG_HASH" = "" ] || [ "$PKG_HASH" = "null" ]; then
		return 1
	fi

	termux_download "${TERMUX_REPO_URL[${idx}-1]}/${PKG_PATH}" \
				"${TERMUX_COMMON_CACHEDIR}-${PACKAGE_ARCH}/${PKG_FILE}" \
				"$PKG_HASH"
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
	termux_download_deb_pac "$@"
fi