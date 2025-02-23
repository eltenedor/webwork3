package WeBWorK3::Controller::User;
use Mojo::Base 'Mojolicious::Controller', -signatures;

use Data::Dump qw/dd/;

sub getGlobalUsers {
	my $self = shift;
	my @global_users =  $self->schema->resultset("User")->getAllGlobalUsers;
	$self->render(json => \@global_users);
	return;
}

sub getGlobalUser {
	my $self = shift;
	my $user = $self->schema->resultset("User")->getGlobalUser( { user_id => int( $self->param("user_id") )} );
	$self->render(json => $user);
	return;
}

sub updateGlobalUser {
	my $self = shift;
	my $user = $self->schema->resultset("User")->updateGlobalUser(
		 { user_id => int( $self->param("user_id") )},
		 $self->req->json );
	$self->render(json => $user);
	return;
}

sub addGlobalUser {
	my $self = shift;
	my $user = $self->schema->resultset("User")->addGlobalUser($self->req->json );
	$self->render(json => $user);
	return;
}

sub deleteGlobalUser {
	my $self = shift;
	my $user = $self->schema->resultset("User")->deleteGlobalUser({user_id => int($self->param("user_id"))});
	$self->render(json => $user);
	return;
}

## the following subs are related to users within a given course.

sub getUsers {
	my $self = shift;
	my @course_users = $self->schema->resultset("User")->getUsers(
		{course_id => int($self->param("course_id"))});
	$self->render(json => \@course_users);
	return;
}

sub getUser {
	my $self = shift;
	my $course_user = $self->schema->resultset("User")->getUser(
		{
			course_id => int($self->param("course_id")),
			user_id => int($self->param("user_id"))
		}
	);
	$self->render(json => $course_user);
	return;
}

sub addUser {
	my $self = shift;
	my $course_user = $self->schema->resultset("User")->addUser(
		{ course_id => int($self->param("course_id"))}, $self->req->json);
	$self->render(json => $course_user);
	return;
}

sub updateUser {
	my $self = shift;
	my $course_user = $self->schema->resultset("User")->updateUser(
		{
			course_id => int($self->param("course_id")),
			user_id => int($self->param("user_id"))
		}, $self->req->json);
	$self->render(json => $course_user);
	return;
}

sub deleteUser {
	my $self = shift;
	my $course_user = $self->schema->resultset("User")->deleteUser(
		{
			course_id => int($self->param("course_id")),
			user_id => int($self->param("user_id"))
		});
	$self->render(json => $course_user);
	return;
}

sub getUserCourses {
	my $self = shift;
	my @user_courses = $self->schema->resultset("Course")
		->getUserCourses({user_id => $self->param('user_id')});
	$self->render(json => \@user_courses);
	return;
}

1;
