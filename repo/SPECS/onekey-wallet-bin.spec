Name:           onekey-wallet-bin
Version:        6.1.0
Release:        1%{?dist}
Summary:        Secure, open-source crypto wallet based on Electron (prebuilt AppImage)

License:        Apache-2.0
URL:            https://onekey.so/

# fix architecture
%ifarch aarch64
    %global target arm64
%else
    %global target %{_target_cpu}
%endif

Source0:        https://github.com/OneKeyHQ/app-monorepo/releases/download/v%{version}/OneKey-Wallet-%{version}-linux-%{target}.AppImage
Source1:        https://github.com/OneKeyHQ/app-monorepo/releases/download/v%{version}/OneKey-Wallet-%{version}-linux-%{target}.AppImage.SHA256SUMS.asc


BuildRequires: curl
BuildRequires: coreutils
BuildRequires: sed
BuildRequires: nodejs
BuildRequires: npm
BuildRequires: gnupg2
BuildRequires: sed
BuildRequires: zlib

ExclusiveArch: aarch64 x86_64



%global _name onekey-wallet

# Disable rpm auto dependency scanning
%global __requires_exclude_from ^/usr/lib/%{_name}/.*
%global __provides_exclude_from ^/usr/lib/%{_name}/.*


%description
Secure, open source and community-driven crypto wallet. This version uses the official AppImage.

%prep

# make AppImage available for sha256sum
cp %{SOURCE0} .

# validate data
gpg --keyserver keys.openpgp.org --recv-keys EB68AE544F1FDD8CD264624FB369A67A90BF387B
gpg --decrypt "%{SOURCE1}" > "%{SOURCE0}.SHA256SUMS"
if [ $? -ne 0 ]; then
    echo "GPG validation failed!"
    exit 1
fi
sha256sum --check "%{SOURCE0}.SHA256SUMS" 
if [ $? -ne 0 ]; then
    echo "Checksum validation failed!"
    exit 1
fi

# extract image
chmod +x %{SOURCE0}
%{SOURCE0} --appimage-extract > /dev/null
mv squashfs-root appdir

# prepare js source files
find "appdir/resources" -type d -exec chmod 755 {} +
# TODO: Remove workaround, suppress errors. Extraction would fail because app.asar
# contains references to missing unpacked files. This must be fixed upstream.
npx -y @electron/asar e appdir/resources/app.asar app.asar.unpacked || true
find app.asar.unpacked/dist/ -type f -exec sed -i "s|process.resourcesPath|'\/usr\/lib\/%{_name}\/resources'|g" {} +
npx -y @electron/asar p app.asar.unpacked appdir/resources/app.asar

# prepare AppRun script
sed -i 's|APPDIR="\$path"|APPDIR=/usr/lib/%{_name}|' appdir/AppRun

# prepare desktop file
sed -i 's|AppRun --no-sandbox|%{_name}|' appdir/%{_name}.desktop
mv appdir/%{_name}.desktop %{_name}.desktop

# create start sscript
cat << EOF > %{_name}.sh
#!/bin/sh
/usr/lib/%{_name}/AppRun --no-sandbox
EOF

%build
# Nothing to build

%install

install -Dm755 %{_name}.sh %{buildroot}/usr/bin/%{_name}
install -Dm644 %{_name}.desktop %{buildroot}/usr/share/applications/%{_name}.desktop
install -Dm644 appdir/usr/share/icons/hicolor/512x512/apps/%{_name}.png %{buildroot}/usr/share/icons/hicolor/512x512/apps/%{_name}.png

mkdir -p %{buildroot}/usr/lib/%{_name}
cp -r appdir/* %{buildroot}/usr/lib/%{_name}/

%post
if [ -x update-desktop-database ]; then
    update-desktop-database /usr/share/applications >/dev/null 2>&1 || :
fi

%postun
if [ -x update-desktop-database ]; then
    update-desktop-database /usr/share/applications >/dev/null 2>&1 || :
fi

%files
/usr/bin/%{_name}
/usr/lib/%{_name}
/usr/share/applications/%{_name}.desktop
/usr/share/icons/hicolor/512x512/apps/%{_name}.png

%changelog
* Sat Mar 21 2026 Olaf Wriggers <olaf@olwig.xyz> - 6.1.0-1
- Update to v6.1.0
- Suppress app.asar extraction errors due to missing unpacked files (upstream packaging issue)
- Replace asar (depricated) with @electron/asar
- Use npx instead of npm

* Sat Mar 21 2026 Olaf Wriggers <olaf@olwig.xyz> - 6.0.0-1
- Update to v6.0.0

* Tue Jan 27 2026 Olaf Wriggers <olaf@olwig.xyz> - 5.20.0-1
- Update to v5.20.0

* Wed Jan 07 2026 Olaf Wriggers <olaf@olwig.xyz> - 5.19.2-1
- Update to v5.19.2

* Mon Dec 29 2025 Olaf Wriggers <olaf@olwig.xyz> - 5.19.0-1
- Update to v5.19.0

* Thu Dec 04 2025 Olaf Wriggers <olaf@olwig.xyz> - 5.18.0-1
- Update to v5.18.0

* Sat Nov 22 2025 Olaf Wriggers <olaf@olwig.xyz> - 5.17.0-1
- Update to v5.17.0

* Fri Oct 31 2025 Olaf Wriggers <olaf@olwig.xyz> - 5.16.0-1
- Update to v5.16.0

* Sat Oct 18 2025 Olaf Wriggers <olaf@olwig.xyz> - 5.15.0-1
- Update to v5.15.0

* Thu Oct 02 2025 Olaf Wriggers <olaf@olwig.xyz> - 5.13.1-1
- Update to v5.13.1

* Wed Oct 01 2025 Olaf Wriggers <olaf@olwig.xyz> - 5.13.0-1
- Update to v5.13.0

* Tue Sep 16 2025 Olaf Wriggers <olaf@olwig.xyz> - 5.12.1-2
- Disabled automatic dependency generation for bundled AppImage libs
  using __requires_exclude_from / __provides_exclude_from to avoid
  incorrect ARM requires
- Switched to fetching the GPG key from a keyserver instead of using
  a static key file
- Moved source downloads to Source tags; removed manual curl calls
  from %prep

* Sun Sep 07 2025 Olaf Wriggers <olaf@olwig.xyz> - 5.12.1-1
- Update to v5.12.1

* Wed Aug 27 2025 Olaf Wriggers <olaf@olwig.xyz> - 5.12.0-1
- Update to v5.12.0

* Wed Aug 27 2025 Olaf Wriggers <olaf@olwig.xyz> - 5.11.0-1
- Update to v5.11.0

* Thu Jul 03 2025 Olaf Wriggers <olaf@olwig.xyz> - 5.10.0-1
- Update to v5.10.0

* Thu Jul 03 2025 Olaf Wriggers <olaf@olwig.xyz> - 5.9.2-1
- Update to v5.9.2

* Wed Jun 11 2025 Olaf Wriggers <olaf@olwig.xyz> - 5.9.0-1
- Update to v5.9.0

* Wed May 28 2025 Olaf Wriggers <olaf@olwig.xyz> - 5.8.3-1
- Update to v5.8.3

* Sat May 03 2025 Olaf Wriggers <olaf@olwig.xyz> - 5.8.0-1
- Update to v5.8.0

* Mon Apr 21 2025 Olaf Wriggers <olaf@olwig.xyz> - 5.7.1-1
- Initial package with v5.7.1
