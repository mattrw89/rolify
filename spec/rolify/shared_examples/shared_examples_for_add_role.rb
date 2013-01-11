shared_examples_for "#add_role_examples" do |param_name, param_method|
  context "using #{param_name} as parameter" do
    context "with a global role", :scope => :global do
      it "should add the role to the user" do
        expect { subject.add_role "root".send(param_method) }.to change { subject.roles.count }.by(1)
      end

      it "should create a role to the roles table" do
        expect { subject.add_role "moderator".send(param_method) }.to change { role_class.count }.by(1)
      end

      context "considering a new global role" do
        subject { role_class.last }

        its(:name) { should eq("moderator") }
        its(:resource_type) { should be(nil) }
        its(:resource_id) { should be(nil) }
      end

      context "should not create another role" do
        it "if the role was already assigned to the user" do
          subject.add_role "manager".send(param_method)
          expect { subject.add_role "manager".send(param_method) }.not_to change { subject.roles.size }
        end

        it "if the role already exists in the db" do
          role_class.create :name => "god"
          expect { subject.add_role "god".send(param_method) }.not_to change { role_class.count }
        end
      end
    end

    context "with a class scoped role", :scope => :class do
      it "should add the role to the user" do
        expect { subject.add_role "supervisor".send(param_method), Forum }.to change { subject.roles.count }.by(1)
      end

      it "should create a role in the roles table" do
        expect { subject.add_role "moderator".send(param_method), Forum }.to change { role_class.count }.by(1)
      end

      context "considering a new class scoped role" do
        subject { role_class.last }

        its(:name) { should eq("moderator") }
        its(:resource_type) { should eq(Forum.to_s) }
        its(:resource_id) { should be(nil) }
      end

      context "should not create another role" do
        it "if the role was already assigned to the user" do
          subject.add_role "warrior".send(param_method), Forum
          expect { subject.add_role "warrior".send(param_method), Forum }.not_to change { subject.roles.size }
        end

        it "if already existing in the database" do
          role_class.create :name => "hacker", :resource_type => "Forum"
          expect { subject.add_role "hacker".send(param_method), Forum }.not_to change { role_class.count }
        end
      end
    end

    context "with an instance scoped role", :scope => :instance do
      it "should add the role to the user" do
        expect { subject.add_role "visitor".send(param_method), Forum.last }.to change { subject.roles.size }.by(1)
      end

      it "should create a role in the roles table" do
        expect { subject.add_role "member".send(param_method), Forum.last }.to change { role_class.count }.by(1)
      end

      context "considering a new class scoped role" do
        subject { role_class.last }

        its(:name) { should eq("member") }
        its(:resource) { should eq(Forum.last) }
      end

      context "should not create another role" do
        it "if the role was already assigned to the user" do
          subject.add_role "anonymous".send(param_method), Forum.first
          expect { subject.add_role "anonymous".send(param_method), Forum.first }.not_to change { subject.roles.size }
        end

        it "if already existing in the database" do
          role_class.create :name => "ghost", :resource_type => "Forum", :resource_id => Forum.first.id
          expect { subject.add_role "ghost".send(param_method), Forum.first }.not_to change { role_class.count }
        end
      end
    end

    context "with a global role with a specific relation" do
      it "should add the role to the user" do
        expect { subject.add_role "ghost".send(param_method), nil, Organization.first }.to change {subject.roles.size}.by(1)

      end
    end






    #now with an added relation...
    context "with a global role with an added relation", :scope => :global_with_org do
      it "should add the role to the user" do
        expect { subject.add_role "root".send(param_method), nil, org }.to change { subject.roles.count }.by(1)
      end

      it "should create a role to the roles table" do
        expect { subject.add_role "moderator".send(param_method), nil, org }.to change { role_class.count }.by(1)
      end

      context "considering a new global role" do
        subject { role_class.last }

        its(:name) { should eq("moderator") }
        its(:resource_type) { should be(nil) }
        its(:resource_id) { should be(nil) }
        its((Organization.name.downcase << "_id").to_sym) { should be(Organization.first.id) }
      end

      context "should not create another role" do
        it "if the role was already assigned to the user" do
          subject.add_role "manager".send(param_method), nil, org
          expect { subject.add_role "manager".send(param_method), nil, org }.not_to change { subject.roles.size }
        end

        it "if the role already exists in the db" do
          role_class.create :name => "god", :organization_id => org.id
          expect { subject.add_role "god".send(param_method), nil, org }.not_to change { role_class.count }
        end
      end
    end

    context "with a class scoped role", :scope => :class_with_org do
      it "should add the role to the user" do
        expect { subject.add_role "supervisor".send(param_method), Forum, org }.to change { subject.roles.count }.by(1)
      end

      it "should create a role in the roles table" do
        expect { subject.add_role "moderator".send(param_method), Forum, org }.to change { role_class.count }.by(1)
      end

      context "considering a new class scoped role" do
        subject { role_class.last }

        its(:name) { should eq("moderator") }
        its(:resource_type) { should eq(Forum.to_s) }
        its(:resource_id) { should be(nil) }
        its((Organization.name.downcase << "_id").to_sym) { should be(Organization.first.id) }
      end

      context "should not create another role" do
        it "if the role was already assigned to the user" do
          subject.add_role "warrior".send(param_method), Forum, org
          expect { subject.add_role "warrior".send(param_method), Forum, org }.not_to change { subject.roles.size }
        end

        it "if already existing in the database" do
          role_class.create :name => "hacker", :resource_type => "Forum", :organization_id => org.id
          expect { subject.add_role "hacker".send(param_method), Forum, org }.not_to change { role_class.count }
        end
      end
    end

    context "with an instance scoped role", :scope => :instance_with_org do
      it "should add the role to the user" do
        expect { subject.add_role "visitor".send(param_method), Forum.last, org }.to change { subject.roles.size }.by(1)
      end

      it "should create a role in the roles table" do
        expect { subject.add_role "member".send(param_method), Forum.last, org }.to change { role_class.count }.by(1)
      end

      context "considering a new class scoped role" do
        subject { role_class.last }

        its(:name) { should eq("member") }
        its(:resource) { should eq(Forum.last) }
        its((Organization.name.downcase << "_id").to_sym) { should be(Organization.first.id) }
      end

      context "should not create another role" do
        it "if the role was already assigned to the user" do
          subject.add_role "anonymous".send(param_method), Forum.first, org
          expect { subject.add_role "anonymous".send(param_method), Forum.first, org }.not_to change { subject.roles.size }
        end

        it "if already existing in the database" do
          role_class.create :name => "ghost", :resource_type => "Forum", :resource_id => Forum.first.id, :organization_id => org.id
          expect { subject.add_role "ghost".send(param_method), Forum.first, org }.not_to change { role_class.count }
        end
      end
    end
  end
end