require './test/integration_helper'

class NongCurriculum
  def slugs
    %w(one two)
  end

  def locale
    Locale.new('nong', 'no', 'not')
  end
end

class ApprovalTest < Minitest::Test

  attr_reader :submission, :admin, :user, :curriculum
  def setup
    @curriculum = Curriculum.new('/tmp')
    @curriculum.add NongCurriculum.new
    @admin = User.create(username: 'alice', github_id: 1, is_admin: true)
    @user = User.create(username: 'bob', current: {'nong' => 'one'}, github_id: 2)

    attempt = Attempt.new(user, 'CODE', 'one.no', curriculum).save
    @submission = Submission.first
  end

  def teardown
    Mongoid.reset
  end

  def test_approve_a_submission_sets_the_state
    Approval.new(submission.id, admin, nil, curriculum).save
    submission.reload
    assert_equal 'approved', submission.state
  end

  def test_approve_submission_sets_approval_time
    Approval.new(submission.id, admin, nil, curriculum).save
    submission.reload
    assert !submission.approved_at.nil?
  end

  def test_approve_submission_sets_approver
    Approval.new(submission.id, admin, nil, curriculum).save
    submission.reload
    assert_equal admin, submission.approver
  end

  def test_approve_submission_saves_comment
    Approval.new(submission.id, admin, 'very nice', curriculum).save
    submission.reload
    assert_equal 'very nice', submission.nits.first.comment
  end

  def test_approve_submission_with_empty_comment_leaves_comment_off
    Approval.new(submission.id, admin, '', curriculum).save
    submission.reload
    assert_equal [], submission.nits
  end

  def test_approve_submission_sets_completed_assignments
    Approval.new(submission.id, admin, nil, curriculum).save
    user.reload
    done = {'nong' => ['one']}
    assert_equal done, user.completed
  end

  def test_approve_last_submission_on_trail_gives_a_dummy_assignment
    Approval.new(submission.id, admin, nil, curriculum).save
    attempt = Attempt.new(user, 'CODE', 'two.no', curriculum).save
    submission = Submission.last
    approval = Approval.new(submission.id, admin, nil, curriculum).save
    assert_equal 'congratulations', approval.submitter.current_on('nong').slug
  end
end

