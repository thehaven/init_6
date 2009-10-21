# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"

inherit autotools eutils python portability

DESCRIPTION="Library for automatic proxy configuration management"
HOMEPAGE="http://code.google.com/p/libproxy/"
SRC_URI="http://${PN}.googlecode.com/files/${P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="alpha amd64 ~arm ~hppa ~ia64 ~ppc ~ppc64 ~sh ~sparc x86 ~x86-fbsd"
IUSE="gnome kde networkmanager python seamonkey webkit "#xulrunner

RDEPEND="
	gnome? (
		x11-libs/libX11
		x11-libs/libXmu
		gnome-base/gconf )
	kde? (
		x11-libs/libX11
		x11-libs/libXmu )
	networkmanager? ( net-misc/networkmanager )
	python? ( >=dev-lang/python-2.5 )
	webkit? ( net-libs/webkit-gtk )
	
"
#	xulrunner? ( >=net-libs/xulrunner-1.9.0.11-r1:1.9 )
#	!xulrunner? ( seamonkey? ( www-client/seamonkey ) )
# Since xulrunner-1.9.0.11-r1 its shipped mozilla-js.pc is fixed so we can use it

DEPEND="${RDEPEND}
	>=dev-util/pkgconfig-0.19"

src_prepare() {
	# Fix test to follow POSIX (for x86-fbsd).
	# FIXME: This doesn't actually fix all == instances when two are on the same line
	#sed -e 's/\(test.*\)==/\1=/g' -i configure.ac configure || die "sed failed"

	eautoreconf
}

src_configure() {
	local myconf

	# xulrunner:1.9 => mozilla;   seamonkey => seamonkey;
	# xulrunner:1.8 => xulrunner; (firefox => mozilla-firefox[-xulrunner] ?)
	#if use xulrunner; then myconf="--with-mozjs=mozilla"
	#elif use seamonkey; then myconf="--with-mozjs=seamonkey"
	#else myconf="--without-mozjs"
	#fi

	econf --with-envvar \
		--with-file \
		--disable-static \
		--without-mozjs \
		$(use_with gnome) \
		$(use_with kde) \
		$(use_with webkit) \
		${myconf} \
		$(use_with networkmanager) \
		$(use_with python)
}

src_compile() {
	emake LIBDL="$(dlopen_lib)" || die
}

src_install() {
	emake DESTDIR="${D}" LIBDL="$(dlopen_lib)" install || die "emake install failed!"
	dodoc AUTHORS NEWS README ChangeLog || die "dodoc failed"
}

pkg_postinst() {
	if use python; then
		python_need_rebuild
		python_mod_optimize "$(python_get_sitedir)/${PN}.py"
	fi
}

pkg_postrm() {
	python_mod_cleanup /usr/$(get_libdir)/python*/site-packages/${PN}.py
}
