use inc::Module::Install;
use strict;
use warnings;
require 5.008006;

name('Angerwhale');
abstract('exciting new weblogging software or something');
author('Jonathan Rockway <jrockway@cpan.org>');
version_from('lib/Angerwhale.pm');
include('ExtUtils::AutoInstall');
licence('gpl');

requires 
  (
   'Algorithm::IncludeExclude'                   => '0.01',
   'Catalyst'                                    => '5.7',          
   'Catalyst::Model::XML::Feed'                  => '0.01',
   'Catalyst::Component::ACCEPT_CONTEXT'         => '0.02',
   'Catalyst::Plugin::Cache'                     => '0.02',
   'Catalyst::Plugin::Cache::Store::FastMmap'    => '0.01',
   'Catalyst::Plugin::ConfigLoader'              => 0,
   'Catalyst::Plugin::ConfigLoader::Environment' => '0.01',
   'Catalyst::Plugin::LogWarnings'               => 0,
   'Catalyst::Plugin::Session'                   => 0,
   'Catalyst::Plugin::Session::State::Cookie'    => 0,
   'Catalyst::Plugin::Session::Store::FastMmap'  => 0,
   'Catalyst::Plugin::Setenv'                    => 0,
   'Catalyst::Plugin::Static::Simple'            => 0,
   'Catalyst::Plugin::Unicode'                   => '0.2',
   'Catalyst::View::TT'                          => 0,
   'Catalyst::View::JSON'                        => 0,
   'Catalyst::View::Jemplate'                    => 0,
   'Class::C3'                                   => 0,
   'Compress::Zlib'                              => 0,
   'Crypt::Blowfish'                             => 0,
   'Crypt::CAST5_PP'                             => 0,
   'Crypt::DES_EDE3'                             => 0,
   'Crypt::IDEA'                                 => 0, 
   'Crypt::OpenPGP'                              => '1.03',
   'Crypt::RIPEMD160'                            => 0,
   'Crypt::Random'                               => '1.25',
   'Crypt::Rijndael'                             => 0,
   'Crypt::Twofish'                              => '2.00',
   'Data::GUID'                                  => '0.04',
   'Digest::MD5'                                 => 0,
   'Digest::SHA1'                                => 0,
   'File::Attributes'                            => 0,
   'File::Attributes::Recursive'                 => 0,
   'File::CreationTime'                          => '2.03',
   'File::Find'                                  => 0,
   'File::Remove'                                => 0,
   'File::Slurp'                                 => '9999.12',
   'File::Temp'                                  => 0,
   'File::Path'                                  => 0,
   'File::Spec'                                  => 0,
   'GD::SecurityImage'                           => 0,
   'HTML::SBC'                                   => 0,
   'HTML::TreeBuilder'                           => 0,
   'HTTP::Date'                                  => 0,
   'IO::String'                                  => 0,
   'JSON'                                        => 0,
   'Module::Pluggable'                           => 0,
   'NEXT'                                        => '0.60',
   'Pod::Simple::Text'                           => 0,
   'POSIX'                                       => 0,
   'Pod::Xhtml'                                  => '1.52_01',
   'Quantum::Superpositions'                     => 0,
   'Scalar::Defer'                               => 0,
   'Scalar::Util'                                => 0,
   'Syntax::Highlight::Engine::Kate'             => '0.02',
   'TeX::Hyphen'                                 => 0,
   'Template::Plugin::Filter'                    => 0,
   'Template::Plugin::Lingua::EN::Inflect'       => 0,
   'Text::Autoformat'                            => 0,
   'Text::Markdown'                              => 0,
   'Text::Textile'                               => 0,
   'Text::WikiFormat'                            => '0.77',
   'Time::Duration'                              => 0,
   'URI'                                         => 0,
   'URI::Escape'                                 => '3.28',
   'URI::Find'                                   => 0,
   'XML::Atom::SimpleFeed'                       => '0.8',
   'XML::Feed'                                   => '0.11',
   'YAML'                                        => '0.60', 
   'YAML::Syck'                                  => '0.71', 
   'base'                                        => 0,
   'version'                                     => 0,
  );
build_requires
  (
   'Test::More'                                  => 0,
   'ok'                                          => 0,
   'Directory::Scratch'                          => '0.12',
   'Test::HTML::Tidy'                            => 0,
   'Test::Strict'                                => 0,
   'Test::NoTabs'                                => 0,
   'Test::Exception'                             => 0,
   'HTML::Tidy'                                  => '1.08',
   'Test::XML::Valid'                            => 0,
   'Test::YAML::Valid'                           => '0.02',
   'Test::JSON'                                  => 0,
   'Test::WWW::Mechanize::Catalyst'              => 0,
   'Path::Class',                                => 0,
  );

feature('Speed up crypto', ['Math::BigInt::GMP' => 0]);

catalyst_par_classes(qw/
    Crypt::Blowfish
    Crypt::CAST5_PP
    Crypt::DES_EDE3
    Crypt::IDEA
    Crypt::OpenPGP
    Crypt::OpenPGP::Key::Public::DSA
    Crypt::OpenPGP::Key::Public::ElGamal
    Crypt::OpenPGP::Key::Public::RSA
    Crypt::OpenPGP::Marker
    Crypt::OpenPGP::OnePassSig
    Crypt::OpenPGP::Trust
    Crypt::RIPEMD160
    Crypt::Random
    Crypt::Rijndael
    Crypt::Twofish
    HTML::SBC
    Pod::Xhtml
    Syntax::Highlight::Engine::Kate
    Syntax::Highlight::Engine::Kate::All
    TeX::Hyphen
    TeX::Hyphen::czech
    Text::Markdown
    Text::Textile
    Text::WikiFormat
    URI::Find
/);

catalyst();
install_script(glob('script/*.pl'));
auto_install();
license('GPL');
tests('t/*/*.t');

WriteAll( sign => 1, meta => 1 );

sub MY::postamble {
    return <<'POSTAMBLE';
run:
	$(PERL) script/angerwhale_server.pl -r -d
profile:
	$(PERL) -d:DProf script/angerwhale_server.pl -d
angerwhale.par: catalyst_par
angerwhale_par: catalyst_par
TAGS: $(MAN3PODS) $(TEST_FILES)
	find lib t | egrep '[.](t|pm)$$' | etags --lang=perl -
POSTAMBLE

}
