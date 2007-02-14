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
   'Algorithm::IncludeExclude'                              => '0.01',
   'Catalyst'                                               => '5.7',          
#   'Catalyst::View::TT::ForceUTF8'                          => 0,
   'Catalyst::Plugin::Cache'                                => 0.02,
   'Catalyst::Plugin::Cache::Store::FastMmap'               => 0.01,
   'Catalyst::Plugin::ConfigLoader'                         => 0,
   'Catalyst::Plugin::ConfigLoader::Environment'            => '0.01',
   'Catalyst::Plugin::LogWarnings'                          => 0,
   'Catalyst::Plugin::Setenv'                               => 0,
   'Catalyst::Plugin::Static::Simple'                       => 0,
   'Catalyst::Plugin::Unicode'                              => '0.2',
   'Catalyst::Plugin::Session::Store::FastMmap'             => 0,
   'Catalyst::Plugin::Session::State::Cookie'               => 0,
   'Catalyst::Plugin::Session'                              => 0,
   'Catalyst::Model::XML::Feed'                             => '0.01',
   'Class::C3'                                              => 0,
   'Crypt::Blowfish'                                        => 0,
   'Crypt::CAST5_PP'                                        => 0,
   'Crypt::DES_EDE3'                                        => 0,
   'Crypt::OpenPGP'                                         => '1.03',
   'Crypt::RIPEMD160'                                       => 0,
   'Crypt::Random'                                          => '1.25',
   'Crypt::Rijndael'                                        => 0,
   'Crypt::Twofish'                                         => '2.00',
   'Data::GUID'                                             => '0.04',
   'Digest::MD5'                                            => 0,
   'Digest::SHA1'                                           => 0,
   'File::Attributes'                                       => 0,
   'File::Attributes::Recursive'                            => 0,
   'File::CreationTime'                                     => '2.03',
   'File::Find'                                             => 0,
   'File::Slurp'                                            => '9999.12',
   'File::Temp'                                             => 0,
   'File::Remove'                                           => 0,
   'HTML::TreeBuilder'                                      => 0,
   'HTTP::Date'                                             => 0,
   'Module::Pluggable'                                      => 0,
   'NEXT'                                                   => '0.60',
   'Pod::Xhtml'                                             => 0,
   'Pod::Simple::Text'                                      => 0,
   'Quantum::Superpositions'                                => 0,
   'Scalar::Util'                                           => 0,
   'Syntax::Highlight::Engine::Kate'                        => 0,
   'Template::Plugin::Lingua::EN::Inflect'                  => 0,
   'Template::Plugin::Filter'                               => 0,
   'Text::Autoformat'                                       => 0,
   'Text::WikiFormat'                                       => '0.77',
   'TeX::Hyphen'                                            => 0,
   'Time::Duration'                                         => 0,
   'URI'                                                    => 0,
   'URI::Escape'                                            => '3.28',
   'XML::Atom::SimpleFeed'                                  => '0.8',
   'XML::Feed'                                              => '0.11',
   'YAML'                                                   => '0.60', 
   'YAML::Syck'                                             => '0.71', 
   'base'                                                   => 0,
   'version'                                                => 0,
   'Crypt::IDEA'                                            => 0, 
   'IO::String'                                             => 0,
   'Text::Textile'                                          => 0,
   'Text::Markdown'                                         => 0,
   'HTML::SBC'                                              => 0,
   'GD::SecurityImage'                                      => 0,
   'Catalyst::View::JSON'                                   => 0,
   'Catalyst::View::Jemplate'                               => 0,
  );
build_requires
  (
   'Test::More'                                             => 0,
   'ok'                                                     => 0,
   'Directory::Scratch'                                     => '0.12',
   'Test::HTML::Tidy'                                       => 0,
   'Test::Strict'                                           => 0,
   'Test::NoTabs'                                           => 0,
   'Test::Exception'                                        => 0,
   'HTML::Tidy'                                             => 0,
   'Test::XML::Valid'                                       => 0,
   'Test::YAML::Valid'                                      => '0.02',
   'Test::WWW::Mechanize::Catalyst'                         => 0,
  );

feature('Speed up crypto', ['Math::BigInt::GMP' => 0]);

catalyst();
install_script(glob('script/*.pl'));
auto_install();
license('GPL');
tests('t/*/*.t');
write_revision() if !-e 'root/revision.tt';
WriteAll( sign => 1, meta => 1 );
catalyst_par_core();
catalyst_par();  

sub write_revision {
# finally, dump the $Revision: $ to a template
    print "Dumping repository revision number to root/revision.tt\n";
    eval {
        open(my $r, '>', 'root/revision.tt') 
          or die "Couldn't open root/revision.tt: $!";

        my $revision;
        if(-d '.svn'){
            $revision = `svn info | grep Revision`;
        }
        else {
            $revision = `svk info | grep Mirrored.From`;
        }
        
        $revision =~ /(\d+)$/;
        die "No revision in repository! (got: $revision)" if !$1;
        
        print {$r} "$1" or die "Write error: $!";
        close $r or die "Couldn't close file: $!";
    };
    if ($@){
        warn $@;
        eval { 
            open(my $r, '>', 'root/revision.tt') 
              or die "Couldn't open root/revision.tt: $!";
            print {$r} "UNKNOWN" or die "Write error: $!";
            close $r or die "Couldn't close file: $!";
        }
    }
    warn $@ if $@; # from the second eval
    
    # if this fails, we'll just use the revision.tt that is bundled.
}

sub MY::postamble {
    return <<'POSTAMBLE';
run:
	$(PERL) script/angerwhale_server.pl -r -d
profile:
	$(PERL) -d:DProf script/angerwhale_server.pl -d
POSTAMBLE

}
