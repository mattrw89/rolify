shared_context "global role", :scope => :global do
  subject { admin }
  
  let(:admin) { user_class.first }
  
  before(:all) do
    load_roles
    create_other_roles
  end
  
  def load_roles
    role_class.destroy_all
    admin.roles = []
    admin.add_role :admin
    admin.add_role :staff
    admin.add_role :manager, Group
    admin.add_role :player, Forum
    admin.add_role :moderator, Forum.last
    admin.add_role :moderator, Group.last
    admin.add_role :anonymous, Forum.first
  end
end

shared_context "class scoped role", :scope => :class do
  subject { manager }
  
  before(:all) do
    load_roles
    create_other_roles
  end
  
  let(:manager) { user_class.where(:login => "moderator").first }
  
  def load_roles
    role_class.destroy_all
    manager.roles = []
    manager.add_role :manager, Forum
    manager.add_role :player, Forum 
    manager.add_role :warrior
    manager.add_role :moderator, Forum.last
    manager.add_role :moderator, Group.last
    manager.add_role :anonymous, Forum.first
  end
end

shared_context "instance scoped role", :scope => :instance do
  subject { moderator }
  
  before(:all) do
    load_roles
    create_other_roles
  end
  
  let(:moderator) { user_class.where(:login => "god").first }
  
  def load_roles
    role_class.destroy_all
    moderator.roles = []
    moderator.add_role :moderator, Forum.first
    moderator.add_role :anonymous, Forum.last
    moderator.add_role :visitor, Forum
    moderator.add_role :soldier
  end
end

shared_context "mixed scoped roles", :scope => :mixed do
  subject { user_class }
  
  before(:all) do
    role_class.destroy_all
  end
    
  let!(:root) { provision_user(user_class.first, [ :admin, :staff, [ :moderator, Group ], [ :visitor, Forum.last ] ]) }
  let!(:modo) { provision_user(user_class.where(:login => "moderator").first, [[ :moderator, Forum ], [ :manager, Group ], [ :visitor, Group.first ]])}
  let!(:visitor) { provision_user(user_class.last, [[ :visitor, Forum.last ]]) }
end

def create_other_roles
  role_class.create :name => "superhero"
  role_class.create :name => "admin", :resource_type => "Group"
  role_class.create :name => "admin", :resource => Forum.first
  role_class.create :name => "VIP", :resource_type => "Forum"
  role_class.create :name => "manager", :resource => Forum.last
  role_class.create :name => "roomate", :resource => Forum.first
  role_class.create :name => "moderator", :resource => Group.first
end

#shared contexts for organization specific roles

shared_context "global role with added relation", :scope => :global_with_org do
  subject { admin }

  let(:admin) { user_class.first }
  let(:org) { Organization.first }

  before(:all) do
    load_roles
    create_other_roles
  end

  def load_roles
    role_class.destroy_all
    admin.roles = []
    admin.add_role :admin, nil, Organization.first
    admin.add_role :staff, nil, Organization.first
    admin.add_role :manager, Group, Organization.first
    admin.add_role :player, Forum, Organization.first
    admin.add_role :moderator, Forum.last, Organization.first
    admin.add_role :moderator, Group.last, Organization.first
    admin.add_role :anonymous, Forum.first, Organization.first
  end
end

shared_context "class scoped role with added relation", :scope => :class_with_org do
  subject { manager }

  before(:all) do
    load_roles
    create_other_roles
  end

  let(:manager) { user_class.where(:login => "moderator").first }
  let(:org) { Organization.first }

  def load_roles
    role_class.destroy_all
    manager.roles = []
    manager.add_role :manager, Forum, Organization.first
    manager.add_role :player, Forum, Organization.first
    manager.add_role :warrior, nil, Organization.first
    manager.add_role :moderator, Forum.last, Organization.first
    manager.add_role :moderator, Group.last, Organization.first
    manager.add_role :anonymous, Forum.first, Organization.first
  end
end

shared_context "instance scoped role with added relation", :scope => :instance_with_org do
  subject { moderator }

  before(:all) do
    load_roles
    create_other_roles
  end

  let(:moderator) { user_class.where(:login => "god").first }
  let(:org) { Organization.first }

  def load_roles
    role_class.destroy_all
    moderator.roles = []
    moderator.add_role :moderator, Forum.first, Organization.first
    moderator.add_role :anonymous, Forum.last, Organization.first
    moderator.add_role :visitor, Forum, Organization.first
    moderator.add_role :soldier, nil, Organization.first
  end
end