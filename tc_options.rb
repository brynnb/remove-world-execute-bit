# Tests for whether the options sent to PermissionUpdater throw errors as expected
#
require './permission_updater'
require 'test/unit'

class TestOptions < Test::Unit::TestCase

  test "an error is raised if invalid options are used" do
    assert_raise(ArgumentError){ PermissionUpdater.new(:recursive => 12345 ) }
    assert_raise(ArgumentError){ PermissionUpdater.new(:recursive => 'string') }
    assert_raise(ArgumentError){ PermissionUpdater.new(:all => 12345 ) }
    assert_raise(ArgumentError){ PermissionUpdater.new(:all => 'string') }
    assert_raise(ArgumentError){ PermissionUpdater.new(:verbose => 12345 ) }
    assert_raise(ArgumentError){ PermissionUpdater.new(:verbose=> 'string') }

    assert_raise(ArgumentError){ PermissionUpdater.new(:path => 12345) }
    assert_raise(ArgumentError){ PermissionUpdater.new(:path => true) }

    assert_raise(ArgumentError){ PermissionUpdater.new(:max_depth => true) }
    assert_raise(ArgumentError){ PermissionUpdater.new(:max_depth => 'string') }
    assert_raise(ArgumentError){ PermissionUpdater.new(:max_depth => 0) }
    assert_raise(ArgumentError){ PermissionUpdater.new(:max_depth => 0.99999) }
    assert_raise(ArgumentError){ PermissionUpdater.new(:max_depth => -1) }

    assert_raise(ArgumentError){ PermissionUpdater.new(:invalid_param => 'doesntmatter') }
  end

  test "an error is not raised if valid options are used" do
    assert_nothing_raised(ArgumentError){ PermissionUpdater.new(:recursive => false ) }
    assert_nothing_raised(ArgumentError){ PermissionUpdater.new(:recursive => true) }
    assert_nothing_raised(ArgumentError){ PermissionUpdater.new(:all => false ) }
    assert_nothing_raised(ArgumentError){ PermissionUpdater.new(:all => true) }
    assert_nothing_raised(ArgumentError){ PermissionUpdater.new(:verbose => false) }
    assert_nothing_raised(ArgumentError){ PermissionUpdater.new(:verbose=> true) }

    assert_nothing_raised(ArgumentError){ PermissionUpdater.new(:path => '/') }
    assert_nothing_raised(ArgumentError){ PermissionUpdater.new(:path => '/directory1') }

    assert_nothing_raised(ArgumentError){ PermissionUpdater.new(:max_depth => 1) }
    assert_nothing_raised(ArgumentError){ PermissionUpdater.new(:max_depth => 999999) }
  end

end
