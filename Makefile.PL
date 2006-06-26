use inc::Module::Install;

name 'Blog';
all_from 'lib/Blog.pm';

requires (Catalyst => '5.66',
	  Carp => 0,
	  Catalyst::Plugin::ConfigLoader => '0.040',
	  Catalyst::Plugin::DefaultEnd => 0,
	  Catalyst::Plugin::Prototype => '1.320',
	  Catalyst::Plugin::Scheduler => 0,
	  Catalyst::Plugin::Static::Simple => '0.140',
	  Crypt::Blowfish => 0,
	  Crypt::CAST5_PP => 0,
	  Crypt::DES_EDE3 => 0,
	  Crypt::OpenPGP => '1.03',
	  Crypt::RIPEMD160 => 0,
	  Crypt::Random => '1.25',
	  Crypt::Rijndael => 0,
	  Crypt::Twofish => '2.00',
	  Data::GUID => '0.04',
	  DateTime => '0.30',
	  Digest::MD5 => 0,
	  Digest::SHA1 => 0,
	  File::CreationTime => 0,
	  File::ExtAttr => '0.04',
	  File::Find => 0,
	  File::Slurp => '9999.12',
	  HTML::TreeBuilder => 0,
	  Module::Pluggable => 0,
	  NEXT => '0.60',
	  Pod::Simple::HTML => 0,
	  Scalar::Util => 0,
	  Text::WikiFormat => '0.77',
	  URI::Escape => '3.28',
	  YAML => '0.58',
	  base => 0,
	  overload => '1.02',
	  version => 0,
#	  Crypt::IDEA => 0,
	 );

catalyst;

install_script glob('script/*.pl');
auto_install;
WriteAll;
