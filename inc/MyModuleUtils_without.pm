# MyModuleUtils_without.pm -- have Module::Utils recognise Module::Mask etc

# Copyright 2010, 2011 Kevin Ryde

# MyModuleUtils_without.pm is shared by several distributions.
#
# MyModuleUtils_without.pm is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# MyModuleUtils_without.pm is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this file.  If not, see <http://www.gnu.org/licenses/>.

package MyModuleUtils_without;
use strict;
use warnings;
use Module::Util;
use Scalar::Util;

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERBOSE = 0;

{
  if ($VERBOSE) {
    print STDERR "Module::Util::find_installed() now wrapped\n";
  }
  if ($VERBOSE >= 2) {
    print STDERR "  \@INC currently: \n",join("\n", @INC),"\n";
  }

  my $orig = \&Module::Util::find_installed;
  my $repl = sub ($;@) {
    my ($module, @inc) = @_;
    if ($VERBOSE >= 2) {
      print STDERR "Module::Util::find_installed() $module\n";
    }

    if (Test::Without::Module->can('get_forbidden_list')) {
      my $href = Test::Without::Module::get_forbidden_list();
      if ($VERBOSE >= 2) { print STDERR "forbidden list: ",join(' ',keys %$href),"\n"; }
      ### $href
      if (exists $href->{$module}) {
        if ($VERBOSE) {
          print STDERR "Module::Util::find_installed() wrap: $module forbidden by Test-Without-Module\n";
        }
        return undef;
      }
    } else {
      if ($VERBOSE >= 2) { print STDERR "Test::Without::Module not loaded\n"; }
    }

    my $module_path = Module::Util::module_path($module);
    if (! @inc) {
      @inc = @INC;
    }
    foreach my $inc (@inc) {
      if ($VERBOSE >= 2) { print STDERR "consider $inc\n"; }
      if (ref $inc) {
        if ($VERBOSE >= 2) { print STDERR "  is a ref\n"; }
        if (Scalar::Util::blessed($inc)
            && $inc->isa('Module::Mask')
            && $inc->is_masked($module)) {
          if ($VERBOSE) {
            print STDERR "Module::Util::find_installed() wrap: $module masked by Module::Mask\n";
          }
          return undef;
        }
      } else {
        my $fullpath = "$inc/$module_path";
        if (-e $fullpath) {
          if ($VERBOSE >= 2) {
            print STDERR "found in dir $inc\n";
          }
          return $fullpath;
        }
      }
    }

    return undef;
  };
  no warnings 'redefine';
  *Module::Util::find_installed = $repl;
}

{
  if ($VERBOSE) {
    print STDERR "Module::Util::find_in_namespace() now wrapped\n";
  }
  if ($VERBOSE >= 2) {
    print STDERR "  \@INC currently: \n",join("\n", @INC),"\n";
  }

  my $orig = \&Module::Util::find_in_namespace;
  my $repl = sub ($;@) {
    my ($namespace, @inc) = @_;
    if ($VERBOSE >= 1) {
      print STDERR "Module::Util::find_in_namespace() $namespace\n";
    }
    my @modules = &$orig ($namespace, @inc);
    @modules = grep {Module::Util::find_installed($_)} @modules;
    if ($VERBOSE >= 1) {
      print STDERR "Module::Util::find_in_namespace() return modules: ",join(' ',@modules),"\n";
    }
    return @modules;
  };
  no warnings 'redefine';
  *Module::Util::find_in_namespace = $repl;
}

# my $path = Module::Util::find_installed('FindBin');
# ### $path
# eval "use Module::Mask 'FindBin'";
# $path = Module::Util::find_installed('FindBin');
# ### $path
# 
# $path = Module::Util::find_installed('SelectSaver');
# ### $path
# eval "use Test::Without::Module 'SelectSaver'";
# my @forbidden = Test::Without::Module::get_forbidden_list();
# ### @forbidden
# $path = Module::Util::find_installed('SelectSaver');
# ### $path

1;
__END__



    # # if ($VERBOSE >= 2) {
    # #   print STDERR "   go to original\n";
    # # }
    # # goto $orig;
# sub inc_hook {
#   my ($self, $filename) = @_;
#   ### @_
#   ###       'Module/Util.pm'
# 
#   return;
# }
# unshift @INC, \&inc_hook;
# ### @INC

    # if (-e 'lib/'.Module::Util::module_path($module)) {
    #   if ($VERBOSE >= 2) {
    #     print STDERR "  under own lib, go to original\n";
    #   }
    #   goto $orig;
    # }
