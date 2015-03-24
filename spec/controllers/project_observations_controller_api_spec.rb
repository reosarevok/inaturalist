require File.dirname(__FILE__) + '/../spec_helper'

shared_examples_for "a ProjectObservationsController" do
  let(:user) { User.make! }
  let(:observation) { Observation.make!(:user => user) }
  let(:project) { Project.make! }
  before(:each) do
    @project_user = ProjectUser.make!(:user => user, :project => project)
  end

  describe "create" do
    it "should work" do
      expect(project.users).to include(user)
      expect {
        post :create, :format => :json, :project_observation => {
          :observation_id => observation.id,
          :project_id => project.id
        }
      }.to change(ProjectObservation, :count).by(1)
    end

    it "should yield JSON for invalid record" do
      expect {
        post :create, :format => :json, :project_observation => {
          :project_id => project.id
        }
      }.not_to raise_error
    end

    it "should yield JSON for invalid record if rules" do
      project.project_observation_fields.create(:observation_field => ObservationField.make!, :required => true)
      expect {
        post :create, :format => :json, :project_observation => {
          :project_id => project.id
        }
      }.not_to raise_error
    end

    describe "with project_id" do
      let(:new_project) { Project.make! }
      it "should add project observation" do
        expect {
          post :create, :format => :json, :project_id => new_project.id, :project_observation => {
            :observation_id => observation.id,
            :project_id => new_project.id
          }
        }.to change(ProjectObservation, :count).by(1)
      end

      it "should add project user" do
        expect(new_project.project_users.where(:user_id => user.id)).to be_blank
        post :create, :format => :json, :project_id => new_project.id, :project_observation => {
          :observation_id => observation.id,
          :project_id => new_project.id
        }
        expect(new_project.project_users.where(:user_id => user.id)).not_to be_blank
      end
    end

    it "should set the user_id" do
      o = Observation.make!
      post :create, format: :json, project_observation: {observation_id: o.id, project_id: project.id}
      po = o.project_observations.last
      expect( po.user_id ).to eq user.id
    end

    it "should not allow addition to invite-only projects if the observer wasn't invited" do
      # p = Project.make!
    end

    describe "with user preferences" do
      let(:other_observation) { Observation.make! }
      it "should work for people other than the observer" do
        pu = ProjectUser.make!(project: project, user: other_observation.user)
        post :create, format: :json, project_observation: {project_id: project.id, observation_id: other_observation.id}
        other_observation.reload
        expect(other_observation.projects.to_a).to include project
      end
      it "should work for projects the observer hasn't joined" do
        post :create, format: :json, project_observation: {project_id: project.id, observation_id: other_observation.id}
        other_observation.reload
        expect(other_observation.projects.to_a).to include project
      end
      it "should not allow non-observers if the observer doesn't allow it" do
        other_observation.user.update_attributes(preferred_project_addition_by: User::PROJECT_ADDITION_BY_NONE)
        post :create, format: :json, project_observation: {project_id: project.id, observation_id: other_observation.id}
        other_observation.reload
        expect(other_observation.projects.to_a).not_to include project
      end
      it "should not allow addition to projects the observer hasn't joined if the observer doesn't allow it" do
        other_observation.user.update_attributes(preferred_project_addition_by: User::PROJECT_ADDITION_BY_JOINED)
        post :create, format: :json, project_observation: {project_id: project.id, observation_id: other_observation.id}
        other_observation.reload
        expect(other_observation.projects.to_a).not_to include project
      end
    end
  end

  it "should destroy" do
    po = ProjectObservation.make!(:observation => observation, :project => project)
    delete :destroy, :format => :json, :id => po.id
    expect(ProjectObservation.find_by_id(po.id)).to be_blank
  end
end

describe ProjectObservationsController, "oauth authentication" do
  let(:token) { double :acceptable? => true, :accessible? => true, :resource_owner_id => user.id }
  before do
    request.env["HTTP_AUTHORIZATION"] = "Bearer xxx"
    allow(controller).to receive(:doorkeeper_token) { token }
  end
  it_behaves_like "a ProjectObservationsController"
end

describe ProjectObservationsController, "devise authentication" do
  before do
    http_login user
  end
  it_behaves_like "a ProjectObservationsController"
end
