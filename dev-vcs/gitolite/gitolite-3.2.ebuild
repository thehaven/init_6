# Copyright 2009-2014 Andrey Ovcharov <sudormrfhalt@gmail.com>
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

# Maintainer notes:
# GitLab has own fork of Gitolite with their patches, see
# https://github.com/gitlabhq/gitolite. It's just few lines changes so I
# exported them to classic patch and modified original Gitolite ebuild.
#

inherit eutils perl-module user versionator

DESCRIPTION="Highly flexible server for git directory version tracker"
HOMEPAGE="http://github.com/sitaramc/gitolite"
SRC_URI="http://milki.github.com/${PN}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="tools vim-syntax gitlab"

DEPEND="dev-lang/perl
	virtual/perl-File-Path
	virtual/perl-File-Temp
	>=dev-vcs/git-1.6.6"
RDEPEND="${DEPEND}
	!dev-vcs/gitolite-gentoo
	vim-syntax? ( app-vim/gitolite-syntax )"

pkg_setup() {
	enewgroup git
	enewuser git -1 /bin/sh /var/lib/gitolite git
}

src_prepare() {
	echo $PF > src/VERSION
	use gitlab && epatch "${FILESDIR}/gitolite-3.2-gitlab.patch"

	# add LOG_TEMPLATE variable to config file
	sed -i \
		-e "/LOG_EXTRA/ a\
		\\\n    # change logs location and their file name pattern.\
		\n    # Default value is HOME/.gitolite/logs/gitolite-%y-%m.log\
		\n    LOG_TEMPLATE                =>  '/var/log/gitolite/gitolite-%y-%m.log'," \
		src/lib/Gitolite/Rc.pm || die "failed to filter Rc.pm"
}

src_install() {
	local uexec=/usr/libexec/${PN}

	rm -rf src/lib/Gitolite/Test{,.pm}
	insinto $VENDOR_LIB
	doins -r src/lib/Gitolite

	dodoc README.txt CHANGELOG

	insopts -m0755
	insinto $uexec
	doins -r src/{commands,syntactic-sugar,triggers,VREF}/

	insopts -m0644
	doins src/VERSION

	exeinto $uexec
	doexe src/gitolite{,-shell}

	dodir /usr/bin
	for bin in gitolite{,-shell}; do
		dosym /usr/libexec/${PN}/${bin} /usr/bin/${bin}
	done

	if use tools; then
		dobin check-g2-compat convert-gitosis-conf
	fi

	keepdir /var/lib/gitolite
	fowners git:git /var/lib/gitolite
	fperms 750 /var/lib/gitolite

	fperms 0644 ${uexec}/VREF/MERGE-CHECK # It's meant as example only

	diropts -m755 -o git -g git
	keepdir /var/log/gitolite
}

pkg_postinst() {
	if [ "$(get_major_version $REPLACING_VERSIONS)" = "2" ]; then
		ewarn
		elog "***NOTE** This is a major upgrade and will likely break your existing gitolite-2.x setup!"
		elog "Please read http://sitaramc.github.com/gitolite/install.html#migr first!"
	fi

	# bug 352291
	ewarn
	elog "Please make sure that your 'git' user has the correct homedir (/var/lib/gitolite)."
	elog "Especially if you're migrating from gitosis."
	ewarn

	elog "Change your user ID to 'git' and run 'gitolite setup -h' to show how"
	elog "to setup Gitolite."
}
