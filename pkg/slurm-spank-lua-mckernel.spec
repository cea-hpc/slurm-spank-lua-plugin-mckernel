#!/usr/bin/rpm
%define  release 1

Summary: Lua plugin to use McKernel from Riken in slurm
Name: slurm-spank-lua-mckernel
Version: 0.1
Release: %{release}
Group: System Environment/Kernel
License: CeCill 2.0
Source0: %{name}-%{version}.tar.gz
BuildRequires: /bin/install, /bin/mkdir
Requires: mckernel, slurm-spank-lua

%description
Lua plugin to use McKernel from Riken in Slurm. It provides all configuration
options to launch McKernel before an user's job.

%prep
%setup -q

%install
mkdir -p %{buildroot}%{_sysconfdir}/slurm/lua.d
install src/mckernel.lua %{buildroot}%{_sysconfdir}/slurm/lua.d
mkdir -p %{buildroot}%{_sysconfdir}/slurm/lua.d/mckernel
install src/config.lua %{buildroot}%{_sysconfdir}/slurm/lua.d/mckernel

%files
%{_sysconfdir}/slurm/lua.d/mckernel.lua
%config(noreplace) %{_sysconfdir}/slurm/lua.d/mckernel/config.lua

%doc README.md AUTHORS
%license Licence_CeCILL_V2-en.txt Licence_CeCILL_V2-fr.txt

%changelog
* Thu Oct 3 2019 - Aurelien Cedeyn <aurelien.cedeyn@cea.fr> - 0.1-1
- Initial packaging
