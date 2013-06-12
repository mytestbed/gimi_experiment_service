
GIMI Experiment Service
=======================

This directory contains the implementations of simple GIMI experiment service which 
allows for the manipulation and observation of experiments and their state.

Installation
------------

At this stage the best course of action is to clone the repository

    % git clone https://github.com/mytestbed/omf_sfa.git
    % cd omf_sfa
    % export OMF_SFA_HOME=`pwd`
    % bundle install
    % cd ..
    % git clone https://github.com/mytestbed/gimi_experiment_service.git
    
Starting the Service
--------------------

To start an AM with a some pre-populated resources ('--test-load-am') from this directory, run the following:

    % cd gimi_experiment_service
    % ruby -I lib -I $OMF_SFA_HOME/lib lib/gimi/exp_service.rb --test-load-state  --dm-auto-upgrade --disable-https start
    
which should result in something like:

    DEBUG Server: options: {:app_name=>"exp_server", :chdir=>"/Users/max/src/gimi_experiment_service", :environment=>"development", :address=>"0.0.0.0", :port=>8002, :timeout=>30, :log=>"/tmp/exp_server_thin.log", :pid=>"/tmp/exp_server.pid", :max_conns=>1024, :max_persistent_conns=>512, :require=>[], :wait=>30, :rackup=>"/Users/max/src/gimi_experiment_service/lib/gimi/exp_service/config.ru", :static_dirs=>["./resources", "/Users/max/src/omf_sfa/lib/omf_common/thin/../../../share/htdocs"], :static_dirs_pre=>["./resources", "/Users/max/src/omf_sfa/lib/omf_common/thin/../../../share/htdocs"], :handlers=>{:pre_rackup=>#<Proc:0x007ffd0ab91388@/Users/max/src/gimi_experiment_service/lib/gimi/exp_service/server.rb:83 (lambda)>, :pre_parse=>#<Proc:0x007ffd0ab91360@/Users/max/src/gimi_experiment_service/lib/gimi/exp_service/server.rb:85 (lambda)>, :pre_run=>#<Proc:0x007ffd0ab91338@/Users/max/src/gimi_experiment_service/lib/gimi/exp_service/server.rb:94 (lambda)>}, :dm_db=>"sqlite:///tmp/gimi_test.db", :dm_log=>"/tmp/gimi_exp_server-dm.log", :load_test_state=>true, :dm_auto_upgrade=>true}
    INFO Server: >> Thin web server (v1.3.1 codename Triple Espresso)
    DEBUG Server: >> Debugging ON
    DEBUG Server: >> Tracing ON
    INFO Server: >> Maximum connections set to 1024
    INFO Server: >> Listening on 0.0.0.0:8002, CTRL+C to stop
    

Testing REST API
----------------

If you started the service with the '--test-load-state' option, the service got preloaded with a few
resources. To list all projects:

    $ curl http://localhost:8002/projects
    {
      "projects_response": {
        "about": "/projects",
        "projects": [
          {
            "name": "projectA",
            "uuid": "989700ca-0bab-4216-9e9d-deb685425906",
            "href": "/projects/989700ca-0bab-4216-9e9d-deb685425906"
          },
          {
            "name": "projectB",
            "uuid": "659b0aa4-de8a-49e2-9775-213feb74a74b",
            "href": "/projects/659b0aa4-de8a-49e2-9775-213feb74a74b"
          }
        ]
      }
    }
    
To list information about a specific project 'projectA', use the following:

    $ curl http://localhost:8002/projects/projectA
    {
      "project_response": {
        "about": "/projects/projectA",
        "type": "project",
        "uuid": "989700ca-0bab-4216-9e9d-deb685425906",
        "href": "/projects/989700ca-0bab-4216-9e9d-deb685425906",
        "name": "projectA",
        "users": [
          {
            "uuid": "ce0a32d2-b95e-4701-890e-7db734c39451",
            "href": "/users/ce0a32d2-b95e-4701-890e-7db734c39451",
            "name": "user1",
            "type": "user"
          }
        ],
        "experiments": [
          {
            "uuid": "fefe295d-4b94-44fa-80c7-0473a9b6b0d4",
            "href": "/experiments/fefe295d-4b94-44fa-80c7-0473a9b6b0d4",
            "name": "exp1",
            "type": "experiment"
          }
        ]
      }
    }

More information about the users associated with a project can be obtained through:

    $ curl http://localhost:8002/projects/projectA/users
    {
      "users_response": {
        "about": "/projects/projectA/users",
        "users": [
          {
            "uuid": "ce0a32d2-b95e-4701-890e-7db734c39451",
            "href": "/users/ce0a32d2-b95e-4701-890e-7db734c39451",
            "name": "user1",
            "type": "user"
          }
        ]
      }
    }
    
The experiments created under a project can be obtained similarly:

    $ curl http://localhost:8002/projects/projectA/experiments
    {
      "experiments_response": {
        "about": "/projects/projectA/experiments",
        "experiments": [
          {
            "uuid": "fefe295d-4b94-44fa-80c7-0473a9b6b0d4",
            "href": "/experiments/fefe295d-4b94-44fa-80c7-0473a9b6b0d4",
            "name": "exp1",
            "type": "experiment"
          }
        ]
      }
    }
    
Exploring the experiments held by the service follows the same lines:

    $ curl http://localhost:8002/experiments
    {
      "experiments_response": {
        "about": "/experiments",
        "experiments": [
          {
            "uuid": "fefe295d-4b94-44fa-80c7-0473a9b6b0d4",
            "href": "/experiments/fefe295d-4b94-44fa-80c7-0473a9b6b0d4",
            "name": "exp1",
            "type": "experiment"
          }
        ]
      }
    }
    
    $ curl http://localhost:8002/experiments/exp1
    {
      "experiment_response": {
        "about": "/experiments/exp1",
        "type": "experiment",
        "uuid": "fefe295d-4b94-44fa-80c7-0473a9b6b0d4",
        "href": "/experiments/fefe295d-4b94-44fa-80c7-0473a9b6b0d4",
        "name": "exp1",
        "iticket": {
          "created_at": "2013-06-06 11:23:49 +1000",
          "valid_until": "2013-09-14 11:23:49 +1000"
        },
        "project": {
          "uuid": "989700ca-0bab-4216-9e9d-deb685425906",
          "href": "/projects/989700ca-0bab-4216-9e9d-deb685425906",
          "name": "projectA",
          "type": "project"
        }
      }
    }
    
And not surprisingly, the same works for users:

    $ curl http://localhost:8002/users
    {
      "users_response": {
        "about": "/users",
        "users": [
          {
            "uuid": "ce0a32d2-b95e-4701-890e-7db734c39451",
            "href": "/users/ce0a32d2-b95e-4701-890e-7db734c39451",
            "name": "user1",
            "type": "user"
          },
          {
            "uuid": "817dee4d-42dd-4d2e-b41e-c4f0a8b0750a",
            "href": "/users/817dee4d-42dd-4d2e-b41e-c4f0a8b0750a",
            "name": "user2",
            "type": "user"
          }
        ]
      }
    }
    
    $ curl http://localhost:8002/users/user1
    {
      "user_response": {
        "about": "/users/user1",
        "type": "user",
        "uuid": "ce0a32d2-b95e-4701-890e-7db734c39451",
        "href": "/users/ce0a32d2-b95e-4701-890e-7db734c39451",
        "name": "user1",
        "projects": [
          {
            "uuid": "989700ca-0bab-4216-9e9d-deb685425906",
            "href": "/projects/989700ca-0bab-4216-9e9d-deb685425906",
            "name": "projectA",
            "type": "project"
          },
          {
            "uuid": "659b0aa4-de8a-49e2-9775-213feb74a74b",
            "href": "/projects/659b0aa4-de8a-49e2-9775-213feb74a74b",
            "name": "projectB",
            "type": "project"
          }
        ]
      }
    }    

### Adding and Modifying Resources

To create a new resource in the context of an existing project, we need to send a POST 
command to the _experiments_ collection.

The simplest way is to request a new experiment with everything set to its default is to send an 
empty POST message to the _experiments_ collection: 

    $ curl-X POST http://localhost:8002/projects/projectB/experiments
    {
      "experiments_response": {
        "about": "/projects/projectB/experiments",
        "experiments": [
          {
            "uuid": "f0eac3fb-58b0-464e-acfb-91c0ab099f62",
            "href": "/experiments/f0eac3fb-58b0-464e-acfb-91c0ab099f62",
            "name": "r70156238177740",
            "type": "experiment"
          }
        ]
      }
    }
    
If we want to create an experiment with a predefined state, or modify an existing one, the following message 
content will achieve that:

    {
      "name": "exp3"
    }
    
If that message is stored in a file `test/new_expriment.json`, the following curl command will create a new
or modify an existing experiment within _projectA_ with _name_ set to _exp3_.
    
    $ curl -X POST -H "Content-Type: application/json" --data-binary @test/new_expriment.json http://localhost:8002/projects/projectB/experiments
    {
      "experiments_response": {
        "about": "/projects/projectB/experiments",
        "experiments": [
          ...
          {
            "uuid": "b84907c6-2b47-4c74-adae-45fb69c85841",
            "href": "/experiments/b84907c6-2b47-4c74-adae-45fb69c85841",
            "name": "exp3",
            "type": "experiment"
          }
        ]
      }
    }

The same can also be achieved with a form encoded POST message:

    $ curl -XPOST -d name=exp4 http://localhost:8002/projects/projectB/experiments{
      "experiments_response": {
        "about": "/projects/projectB/experiments",
        "experiments": [
          ...
          {
            "uuid": "78ef3e4a-9d64-440f-b5f5-5628c9d1c92e",
            "href": "/experiments/78ef3e4a-9d64-440f-b5f5-5628c9d1c92e",
            "name": "exp4",
            "type": "experiment"
          }
        ]
      }
    }
    
### Deleting Resources

To delete a specific resource, simply send a `DELETE` message to its URL. For instance, to delete the above create _exp4_ 
issue the following `curl` command.

    $ curl -X DELETE http://localhost:8002/projects/projectB/experiments/exp4
    {
      "experiments_response": {
        "about": "/projects/projectB/experiments",
        "experiments": [
          {
            "uuid": "303fa157-265a-4805-93c9-429fe73e702d",
            "href": "/experiments/303fa157-265a-4805-93c9-429fe73e702d",
            "name": "exp1",
            "type": "experiment"
          },
          {
            "uuid": "bb34d801-7a2a-46f5-bb66-96cef238dfc9",
            "href": "/experiments/bb34d801-7a2a-46f5-bb66-96cef238dfc9",
            "name": "exp3",
            "type": "experiment"
          }
        ]
      }
    }

To delete ALL experiments for a project, send the `DELETE` message to the experiments collection.

{
  "experiments_response": {
    "about": "/projects/projectB/experiments",
    "experiments": []
  }
}
