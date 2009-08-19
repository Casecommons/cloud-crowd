# A WorkUnit is an atomic chunk of work from a job, processing a single input
# through a single action. All WorkUnits receive the same options.
class WorkUnit < ActiveRecord::Base
  
  belongs_to :job
  
  validates_presence_of :job_id, :status, :input
  
  # Note that COMPLETE and INCOMPLETE are unions of other states.
  named_scope 'processing', :conditions => {:status => Dogpile::PROCESSING}
  named_scope 'pending',    :conditions => {:status => Dogpile::PENDING}
  named_scope 'succeeded',  :conditions => {:status => Dogpile::SUCCEEDED}
  named_scope 'failed',     :conditions => {:status => Dogpile::FAILED}
  named_scope 'complete',   :conditions => {:status => Dogpile::COMPLETE}
  named_scope 'incomplete', :conditions => {:status => Dogpile::INCOMPLETE}
  
  after_save :check_for_job_completion
  
  # After saving a WorkUnit, it's Job should check if it just become complete.
  def check_for_job_completion
    self.job.check_for_completion if complete?
  end
  
  # The work is complete if the WorkUnit failed or succeeded.
  def complete?
    Dogpile::COMPLETE.include? status
  end
  
  # The JSON representation of a WorkUnit contains common elements of its job.
  def to_json(opts={})
    {
      'id'      => self.id,
      'job_id'  => self.job_id,
      'input'   => self.input,
      'action'  => self.job.action,
      'options' => JSON.parse(self.job.options)
    }.to_json
  end
  
end