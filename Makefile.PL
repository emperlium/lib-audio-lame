use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Nick::Audio::LAME',
    VERSION_FROM        => 'lib/Nick/Audio/LAME.pm',
    AUTHOR              => 'Nick Peskett',
    LIBS                => [ '-lmp3lame' ],
    DEFINE              => '-DINCLUDE_LAME_LAME_H',
    TEST_REQUIRES       => {
        'Nick::MP3::Frame' => 0
    }
);
