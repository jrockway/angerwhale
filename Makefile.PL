use inc::Module::Install;

name 'Blog';
all_from 'lib/Blog.pm';

requires (Catalyst => '5.66',
	  Crypt::OpenPGP => '1.03',
	  Carp => 0,
	  Crypt::Random => '1.25',
	  Data::GUID => '0.04',
	  DateTime => '0.30',
	  File::ExtAttr => '0.04',
	  File::CreationTime => '2.01',
	  File::Slurp => '9999.12',
	  NEXT => '0.60',
	  overload => '1.02',
	  YAML => '0.58',
	  URI::Escape => '3.28',
	  Text::WikiFormat => '0.77',
	  version => '0.580',
	  Catalyst::Plugin::Static::Simple => '0.140',
	  Catalyst::Plugin::Prototype => '1.320',
	  Catalyst::Plugin::ConfigLoader => '0.040',
	  Catalyst::Plugin::DefaultEnd => '0.050',
	 );

catalyst;

install_script glob('script/*.pl');
auto_install;
WriteAll;
