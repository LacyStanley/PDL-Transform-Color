use Test::More test=>53;

BEGIN {
    use_ok('PDL::Transform::Color') || print "Bail out!\n";
}

eval "use PDL::Transform::Color;";

ok( $PDL::Transform::Color::VERSION, "looks like there's a version in the module" );
use PDL::Transform;


##########
## test t_gamma
my $t;
eval {$t = PDL::Transform::Color::t_gamma(2);};
ok(!$@, "t_gamma constructor executed OK");

my $itriplet = pdl(0.5,0,1.0);
my $otriplet;
eval {$otriplet = $itriplet->apply($t);};
ok(!$@, "t_gamma transform applied OK");
ok(all(($otriplet * 10000)->rint == ($itriplet**2 * 10000)->rint), "gamma=2 squares the output");
eval {$otriplet = $itriplet->invert($t);};
ok(!$@, "t_gamma transform inverse applied OK");
ok(all(($otriplet * 10000)->rint == ($itriplet**0.5 * 10000)->rint), "gamma=2 inverse square-roots the output");

$itriplet *= pdl(-1,1,1);
eval {$otriplet = $itriplet->apply($t);};
ok(!$@, "t_gamma transform with negative values works OK");
ok(all(($otriplet * 10000)->abs->rint == (($itriplet->abs)**2 * 10000)->rint), "gamma=2 gives correct magnitude with negative input values");
ok($otriplet->((0))<0, "gamma=2 preserves sign");
eval {$otriplet = $itriplet->invert($t);};
ok(!$@, "t_gamma transformm inverts OK on negative values");
ok(all(($otriplet * 10000)->abs->rint == (($itriplet->abs)**0.5 * 10000)->rint), "gamma=2 inverse gives correct magnitude with negative input values");
ok($otriplet->((0))<0, "gamma=2 inverse preserves sign");


##########
# test t_brgb
eval { $t = t_brgb(display_gamma=>1); };
ok(!$@, "t_brgb constructor runs OK");
$itriplet = pdl(0,0.5,1.0);
eval { $otriplet = $itriplet->apply($t); };
ok(!$@, "t_brgb forward transform runs");
ok(all($otriplet == byte pdl(0,128,255)),"gives correct values (values were $otriplet)");
my $i2triplet;
eval { $i2triplet = $otriplet->invert($t); };
ok(!$@, "t_brgb backward transform runs");
ok(all(($i2triplet*100)->rint == ($itriplet * 100)->rint) , "reverse gives correct values");

$t = t_brgb(b=>1, display_gamma=>1);
eval { $otriplet = $itriplet->apply($t) };
ok(!$@, "t_brgb with byte - forward transform runs");
ok($otriplet->type =~ m/byte/, "with b option creates a byte");
ok(all($otriplet==pdl(byte,0,128,255)),"gives correct byte values");
eval { $i2triplet = $otriplet->invert($t) };
ok(!$@, "t_brgb reverse transform runs");
ok($i2triplet->type =~ m/(float|double)/, "reverse transform makes a floater");
ok(all( ($i2triplet * 100)->rint == pdl(long, 0, 50, 100)), "reverse tranform gives correct values (values were $i2triplet)");

$t = t_brgb(gamma=>0.5,b=>1,display_gamma=>1);
$otriplet = $itriplet->apply($t);
ok(all( $otriplet->rint == pdl(long, 0, 180, 255)),"gamma correction on nRGB side works (got $otriplet)");

$t = t_brgb();
$otriplet = $itriplet->apply($t);
ok(all($otriplet== pdl(byte, 0, 186, 255)),"default output gamma correction is 2.2 for t_brgb)");

##########
#

##########
# test t_cmyk
eval { $t = t_cmyk(); };
ok(!$@, "t_cmyk constructor runs");
$itriplet = pdl(0.341,0.341,0.341);
eval { $otriplet = $itriplet->apply($t); };
ok( !$@, "t_cmyk forward runs OK" );
ok( $otriplet->nelem==4, "t_cmyk makes a 4-vector");
ok( all($otriplet->(0:2)==0), "t_cmyk finds an all-k solution");
ok( $otriplet->((3))==1.0  - 0.341, "t_cmyk gets corrrect k value");
eval { $i2triplet = $otriplet->invert($t);};
ok( !$@, "t_cmyk reverse runs OK");
ok( $i2triplet->nelem==3, "t_cmyk inverse makes a 3-vector" );
ok( all( ($i2triplet*10000)->rint == ($itriplet*10000)->rint ), "reverse gets the original");
$itriplet = pdl(0.25,0.35,0.45);
$otriplet = $itriplet->apply($t);
ok(all( ($otriplet*10000)->rint == (pdl(0.444444,0.222222,0,0.55)*10000)->rint), "random non-grey sample");
$i2triplet = $otriplet->invert($t);
ok(all( ($itriplet*10000)->rint == ($i2triplet*10000)->rint), "non-grey sample inverts correctly");


##########
# test t_xyz
$itriplet = pdl([1,0,0],[0,1,0],[0,0,1]);
eval { $otriplet = $itriplet->apply(t_xyz()); };
ok(!$@, "t_xyz runs OK ($@)");
# Check against chromaticities of the sRGB primaries
my $xpypzptriplet = $otriplet / $otriplet->sumover->(*1);
ok( all( ($xpypzptriplet->(0:1)*1000)->rint == 
	 ( pdl( [ 0.640, 0.330 ], 
		[ 0.300, 0.600 ],
		[ 0.150, 0.060 ]
	   )
	   * 1000)->rint
    ),
    "XYZ translation works for R, G, and B vectors");
eval { $i2triplet = $otriplet->invert(t_xyz()); };
ok(!$@, "t_xyz inverse runs OK");
ok( all( ($i2triplet*10000)->rint == ($itriplet*10000)->rint ), "t_xyz inverse works OK");

##########
# test t_rgi
my $brgbcmyw = pdl([0,0,0],
		   [1,0,0],[0,1,0],[0,0,1],
		   [0,1,1],[1,0,1],[1,1,0],
		   [1,1,1]);
my $ocolors;
my $t;
eval { $t = t_rgi(); }; 
ok(!$@, "t_rgi runs OK ($@)");
eval { $ocolors = $brgbcmyw->apply($t) };
ok(!$@, "t_rgi forward transform is OK ($@)");
my $test = pdl([0,0,0],
	       [ 1 , 0 ,   0.3333333 ], [ 0 , 1 ,   0.3333333 ], [ 0 , 0 ,    0.3333333 ],
	       [ 0 , 0.5 , 0.6666667 ], [ 0.5 , 0 , 0.6666667 ], [0.5 , 0.5 , 0.6666667 ],
	       [ 0.3333333 , 0.3333333 , 1         ] 
    );
ok( all( ($test*10000)->rint == ($ocolors*10000)->rint ), "t_rgi passees 8-color test");

##########
# test t_hsl and t_hsv
my $hsltest;
eval { $t = t_hsl(); };
ok(!$@, "t_hsl worked ok");
eval { $hsltest = $brgbcmyw->apply($t); };
ok(!$@, "t_hsl ran ok forward");
ok(all( ($hsltest* 1000)->rint ==
	(pdl([0,0,0],[0,1,0.5],[0.333,1,0.5],[0.667,1,0.5],[0.500,1,0.5],[0.833,1,0.5],[0.167,1,0.5],[0,0,1])*1000)->rint), "hsl forward yielded correct values");
my $hsltest2;
eval { $hsltest2 = $hsltest->invert($t);};
ok(!$@, "t_hsl ran ok backward");
ok(all( ( $brgbcmyw - $hsltest2 )->abs < 1e-4), "t_hsl gave good reverse answers");

eval { $t = t_hsv(); };
ok(!$@, "t_hsv worked ok");
eval { $hsltest = $brgbcmyw->apply($t);};
ok(!$@, "t_hsv ran ok forward");
ok(all( ($hsltest* 1000)->rint ==
	(pdl([0,0,0],[0,1,1],[0.333,1,1],[0.667,1,1],[0.500,1,1],[0.833,1,1],[0.167,1,1],[0,0,1])*1000)->rint), "hsv forward yielded correct values");
eval { $hsltest2 = $hsltest->invert($t);};
ok(!$@, "t_hsv ran ok in reverse");
ok(all( ($brgbcmyw - $hsltest2 )->abs < 1e-4), "t_hsv gave good reverse answers");