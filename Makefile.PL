use inc::Module::Install;

name 'Blog';
all_from 'lib/Blog.pm';

requires Catalyst => '5.64';

catalyst;

install_script glob('script/*.pl');
auto_install;
WriteAll;
