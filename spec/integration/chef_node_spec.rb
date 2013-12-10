require 'support/spec_support'
require 'cheffish/resource/chef_node'
require 'cheffish/provider/chef_node'

describe Cheffish::Resource::ChefNode do
  extend SpecSupport

  when_the_chef_server 'is empty' do
    context 'and we run a recipe that creates node "blah"' do
      with_recipe do
        chef_node 'blah'
      end

      it 'the node gets created' do
        chef_run.should have_updated 'chef_node[blah]', :create
        get('/nodes/blah')['name'].should == 'blah'
      end
    end

    # TODO why-run mode

    context 'and another chef server is running on port 8899' do
      before :each do
        @server = ChefZero::Server.new(:port => 8899)
        @server.start_background
      end

      after :each do
        @server.stop
      end

      context 'and a recipe is run that creates node "blah" on the second chef server using with_chef_server' do

        with_recipe do
          with_chef_server 'http://127.0.0.1:8899'
          chef_node 'blah'
        end

        it 'the node is created on the second chef server but not the first' do
          chef_run.should have_updated 'chef_node[blah]', :create
          lambda { get('/nodes/blah') }.should raise_error(Net::HTTPServerException)
          get('http://127.0.0.1:8899/nodes/blah')['name'].should == 'blah'
        end
      end

      context 'and a recipe is run that creates node "blah" on the second chef server using chef_server' do

        with_recipe do
          chef_node 'blah' do
            chef_server({ :chef_server_url => 'http://127.0.0.1:8899' })
          end
        end

        it 'the node is created on the second chef server but not the first' do
          chef_run.should have_updated 'chef_node[blah]', :create
          lambda { get('/nodes/blah') }.should raise_error(Net::HTTPServerException)
          get('http://127.0.0.1:8899/nodes/blah')['name'].should == 'blah'
        end
      end

    end
  end

  when_the_chef_server 'has a node named "blah"' do
    node 'blah', {}

    with_recipe do
      chef_node 'blah'
    end

    it 'the node "blah" does not get created or updated' do
      chef_run.should_not have_updated 'chef_node[blah]', :create
    end
  end
end
