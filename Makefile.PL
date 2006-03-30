use inc::Module::Install;

name 'Blog';
all_from 'lib/Blog.pm';

requires({Catalyst => '5.64',
	  Crypt::OpenPGP => 0,
	  Carp => 0,
	  Crypt::Random => 0,
	  Data::GUID => 0,
	  DateTime => 0,
	  File::ExtAttr => 0,
	  File::CreationTime => 0,
	  File::Slurp => 0,
	  NEXT => 0,
	  overload => 0,
	  YAML => 0,
	  URI::Escape => 0,
	  Text::WikiFormat => 0,
	 });

catalyst;

install_script glob('script/*.pl');
auto_install;
WriteAll;
