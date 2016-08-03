# Tests for PermissionUpdater handling options correctly and updating world execute bit correctly
#
require './permission_updater'
require 'test/unit'
require 'fakefs/safe'
require 'pp' # Due to FakeFS bug: https://github.com/fakefs/fakefs/issues/99


class TestFileHandling < Test::Unit::TestCase

  self.test_order = :defined # So that tests run in order, makes debugging easier

  ROOT_FILES_X = 50 # "x" will be our signifier for files that have world execute bit enabled
  ROOT_FILES = 50
  HIDDEN_FILES = 10
  HIDDEN_FILES_X = 10
  FILES_PER_DIRECTORY_X = 25
  FILES_PER_DIRECTORY = 25
  NUMBER_OF_DIRECTORIES = 2
  TOTAL_FILES = ROOT_FILES_X + ROOT_FILES + HIDDEN_FILES + HIDDEN_FILES_X + (NUMBER_OF_DIRECTORIES * FILES_PER_DIRECTORY_X) + (NUMBER_OF_DIRECTORIES * FILES_PER_DIRECTORY)

  def self.startup
    FakeFS.activate!
  end

  # Make root directory files with FakeFS and call function to create subdirectories if NUMBER_OF_DIRECTORIES > 0
  #
  def setup

    for i in 1..ROOT_FILES_X
      File.open("/rootfilex#{i}.txt", 'w+').chmod(0777) #Just using random permissions aside from having world execute bit included or not
      # puts "rootfilex#{i}.txt"
    end

    for i in (ROOT_FILES_X + 1)..(ROOT_FILES + ROOT_FILES_X)
      File.open("/rootfile#{i}.txt", 'w+').chmod(0660)
      # puts "rootfile#{i}.txt"
    end

    for i in 1..HIDDEN_FILES_X
      File.open("/.hiddenfilex#{i}", 'w+').chmod(0555)
      # puts ".hiddenfile#{i}"
    end

    for i in (HIDDEN_FILES_X + 1)..(HIDDEN_FILES + HIDDEN_FILES)
      File.open("/.hiddenfile#{i}", 'w+').chmod(0442)
      # puts ".hiddenfile#{i}"
    end

    make_test_dirs_with_files("/", 1)

  end

  # Recursively make subdirectories and files to match NUMBER_OF_DIRECTORIES
  #
  def make_test_dirs_with_files(parent, count)
    unless count > NUMBER_OF_DIRECTORIES
      Dir.mkdir(parent + "directory#{count}/")
      # puts parent + "/directory#{count}"

      for i in 1..FILES_PER_DIRECTORY_X
        File.open(parent + "directory#{count}/" + "filex#{i}.txt", 'w+').chmod(0331)
        # puts parent + "/directory#{count}/" + "filex#{i}.txt"
      end

      for i in (FILES_PER_DIRECTORY_X + 1)..(FILES_PER_DIRECTORY + FILES_PER_DIRECTORY_X)
        File.open(parent + "directory#{count}/" + "file#{i}.txt", 'w+').chmod(0224)
        # puts parent + "/directory#{count}/" + "file#{i}.txt"
      end

      make_test_dirs_with_files(parent + "directory#{count}/", (count + 1))

    end

  end


  test "hidden files not processed by default" do
    updater = PermissionUpdater.new
    files = updater.update_permissions
    assert_equal(ROOT_FILES + ROOT_FILES_X, files.length)
  end

  test "hidden files processed when --all option enabled" do
    updater = PermissionUpdater.new(:all => true)
    files = updater.update_permissions
    assert_equal(ROOT_FILES + ROOT_FILES_X + HIDDEN_FILES + HIDDEN_FILES_X, files.length)
  end

  test "non-root files not processed by default" do
    updater = PermissionUpdater.new
    files = updater.update_permissions
    assert_equal(ROOT_FILES + ROOT_FILES_X, files.length)
  end

  test "non-root files processed when --recursive option enabled" do
    updater = PermissionUpdater.new(:recursive => true)
    files = updater.update_permissions
    assert_equal(TOTAL_FILES - HIDDEN_FILES - HIDDEN_FILES_X, files.length)
  end

  test "all files processed with --recursive and --all options enabled" do
    updater = PermissionUpdater.new(:recursive => true, :all => true)
    files = updater.update_permissions
    assert_equal(TOTAL_FILES, files.length)
  end

  test "max_depth processes only files above depth with --max_depth options set" do
    depth = 2
    updater = PermissionUpdater.new(:max_depth => depth)
    files = updater.update_permissions
    assert_equal(ROOT_FILES_X + ROOT_FILES + (FILES_PER_DIRECTORY_X * (depth - 1)) + (FILES_PER_DIRECTORY * (depth - 1)), files.length)
  end

  test "max_depth processes only files above depth with --max_depth options set to higher number" do
    test_depth = 3
    actual_depth = [NUMBER_OF_DIRECTORIES + 1, test_depth].min # can test with high depth numbers, but for calculating number of files that *should* be there, max out at the constant provided
    updater = PermissionUpdater.new(:max_depth => test_depth)
    files = updater.update_permissions
    assert_equal(ROOT_FILES_X + ROOT_FILES + (FILES_PER_DIRECTORY_X * (actual_depth - 1)) + (FILES_PER_DIRECTORY * (actual_depth - 1)), files.length)
  end

  test "max_depth processes only root files with --max_depth option set to 1" do
    updater = PermissionUpdater.new(:max_depth => 1)
    files = updater.update_permissions
    assert_equal(ROOT_FILES_X + ROOT_FILES, files.length)
  end

  test "setting --path processes only files in path" do
    updater = PermissionUpdater.new(:path => '/directory1')
    files = updater.update_permissions
    assert_equal(FILES_PER_DIRECTORY_X + FILES_PER_DIRECTORY, files.length)
  end

  test "setting --path and --recursive processes only files in path and below" do
    updater = PermissionUpdater.new(:path => '/directory1', :recursive => true)
    files = updater.update_permissions
    assert_equal((FILES_PER_DIRECTORY_X + FILES_PER_DIRECTORY) * NUMBER_OF_DIRECTORIES, files.length)
  end

  test "setting --path and --max_depth processes only files in path and below to max_depth" do
    depth = 2
    updater = PermissionUpdater.new(:path => '/directory1', :max_depth => depth)
    files = updater.update_permissions
    assert_equal((FILES_PER_DIRECTORY_X + FILES_PER_DIRECTORY) * depth, files.length)
  end

  test "setting --path and --max_depth to 1 processes only files in path" do
    updater = PermissionUpdater.new(:path => '/directory1', :max_depth => 1)
    files = updater.update_permissions
    assert_equal((FILES_PER_DIRECTORY_X + FILES_PER_DIRECTORY), files.length)
  end

  test "file permissions after running do not include any world execute bits" do # TODO: Should probably add a check for this under all other testing circumstances and permission settings
    updater = PermissionUpdater.new(:all => true, :recursive => true)
    files = updater.update_permissions
    assert_equal(updater.get_updated_files.length, (TOTAL_FILES / 2)) # since we have half the files set to be world execute
    # TODO: Need to change the divisor of "2" to be more dynamic because this doesn't account for changing constant values

    updater_checker = PermissionUpdater.new(:all => true, :recursive => true)
    updater_checker.update_permissions
    assert_equal(0, updater_checker.get_updated_files.length)
  end

  # TODO: Could probably make test for verbose option, but a bit time consuming for low usefulness

  # TODO: Would be more bullet proof to include tests for all combinations of permissions but very time consuming to run

  # TODO: Might be useful to have tests focused on ensuring class types/descendents/methods exist as expected

  def teardown
    FakeFS::FileSystem.clear # wipe file system for new test
  end

  def self.shutdown
    FakeFS.deactivate!
  end

end
