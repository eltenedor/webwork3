use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use Data::Dump qw/dd/;

BEGIN {
	use File::Basename qw/dirname/;
	use Cwd qw/abs_path/;
	$main::test_dir = abs_path( dirname(__FILE__) );
	$main::lib_dir  = dirname( dirname($main::test_dir) ) . '/lib';
}

use Getopt::Long;
my $TEST_PERMISSIONS;
GetOptions ("perm"  => \$TEST_PERMISSIONS);  # check for the flag --perm when running this.

use lib "$main::lib_dir";

use DB::Schema;

# this tests the api with common courses routes

# load the database
my $db_file = "$main::test_dir/../../t/db/sample_db.sqlite";
my $schema  = DB::Schema->connect("dbi:SQLite:$db_file");

my $t;

if ($TEST_PERMISSIONS) {
	$t = Test::Mojo->new( WeBWorK3 => { ignore_permissions => 0, secrets => [1234] } );

	# and login
	$t->post_ok( '/api/login' => json => { email => 'admin@google.com', password => 'admin' } )
		->content_type_is('application/json;charset=UTF-8')
		->json_is( '/logged_in' => 1 )
		->json_is( '/user/user_id' => 1 )
		->json_is( '/user/is_admin' => 1 );

} else {
	$t = Test::Mojo->new( WeBWorK3 => { ignore_permissions => 1, secrets => [1234] });
}


$t->get_ok('/webwork3/api/courses')
	->content_type_is('application/json;charset=UTF-8')
	->json_is( '/0/course_name' => "Precalculus" )
	->json_is( '/0/visible' => 1 );

$t->get_ok('/webwork3/api/courses/1')
	->content_type_is('application/json;charset=UTF-8')
	->json_is( '/course_name' => "Precalculus" )
	->json_is( '/visible' => 1);



## add a new course

my $new_course = {
	course_name   => "Linear Algebra",
	# course_setting => {
		# general => {
		# 	institution => "Springfield A&M"
		# },
		# optional    => {},
		# permissions => {},
		# problem     => {},
		# problem_set => {},
		# email => {},
	# },
	course_dates  => { start       => "2021-05-31", end => "2021-07-01" }
};

$t->post_ok( '/webwork3/api/courses' => json => $new_course )->status_is(200)
	->json_is( '/course_name' => $new_course->{course_name} );

# Pull out the id from the response
my $new_course_id = $t->tx->res->json('/course_id');
$new_course->{course_id} = $new_course_id;
is_deeply( $new_course, $t->tx->res->json, "addCourse: courses match" );

## update the course

$new_course->{visible} = 0;
$t->put_ok( "/webwork3/api/courses/$new_course_id" => json => $new_course )
	->status_is(200)
	->json_is( '/course_name' => $new_course->{course_name} );

is_deeply( $new_course, $t->tx->res->json, "updateCourse: courses match" );
dd $new_course;
dd $t->tx->res->json;

## test for exceptions

# a set that is not in a course
$t->get_ok("/webwork3/api/courses/99999")
	->content_type_is('application/json;charset=UTF-8')
	->json_is( '/exception' => 'DB::Exception::CourseNotFound' );

# try to update a non-existant course

$t->put_ok( "/webwork3/api/courses/999999" => json => { course_name => 'new course name' } )
	->content_type_is('application/json;charset=UTF-8')
	->json_is( '/exception' => 'DB::Exception::CourseNotFound' );

# try to add a course without a course_name

my $another_new_course = { name => "this is the wrong field" };

$t->post_ok( "/webwork3/api/courses/" => json => $another_new_course )
	->content_type_is('application/json;charset=UTF-8')
	->json_is( '/exception' => 'DB::Exception::ParametersNeeded' );

# try to delete a non-existent course.
$t->delete_ok("/webwork3/api/courses/9999999")
	->content_type_is('application/json;charset=UTF-8')
	->json_is( '/exception' => 'DB::Exception::CourseNotFound' );

# delete the added course

$t->delete_ok("/webwork3/api/courses/$new_course_id")
->status_is(200)
->json_is( '/course_name' => $new_course->{course_name} );

## login a non admin user

if ($TEST_PERMISSIONS){

	$t->post_ok( '/webwork3/api/login' => json => { email => 'lisa@google.com', password => 'lisa' } )
		->content_type_is('application/json;charset=UTF-8')
		->json_is( '/logged_in' => 1 )
		->json_is( '/user/login' => "lisa" )
		->json_is( '/user/is_admin' => 0 );

	$t->get_ok('/webwork3/api/courses')
		->content_type_is('application/json;charset=UTF-8')
		->json_is( '/0/course_name' => "Precalculus" )
		->json_is( '/0/course_params/institution' => "Springfield CC" );

	$t->get_ok('/webwork3/api/courses/1')
		->content_type_is('application/json;charset=UTF-8')
		->json_is( '/course_name' => "Precalculus" )
		->json_is( '/course_params/institution' => "Springfield CC" );

	# the following shouldn't have permissions for these routes.

	$t->post_ok( '/webwork3/api/courses' => json => $new_course )
		->status_is(200)
		->json_is( '/has_permission' => 0 );

	$t->put_ok( "/webwork3/api/courses/1" => json => { course_name => "XXX" } )
		->status_is(200)
		->json_is( '/has_permission' => 0 );

	$t->delete_ok("/webwork3/api/courses/1")
		->status_is(200)
		->json_is( '/has_permission' => 0 );
}

done_testing;
