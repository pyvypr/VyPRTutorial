# script to pull the relevant code from the repositories
# VyPRServer, which requires VyPR
# SampleWebService, which requires VyPR

# we may want to use virtual environments for dependencies at some point...
# at the moment we don't need it, but it's worth considering.

echo "Working in:";
pwd;

echo "Pulling all code again."
# remove current versions
rm -rf VyPRServer SampleWebService;
# clone the new versions
echo "Cloning VyPRServer...";
git clone git@github.com:pyvypr/VyPRServer.git;
echo "Cloning SampleWebService...";
git clone git@github.com:pyvypr/SampleWebService.git;
echo "Cloning VyPR into VyPRServer and SampleWebService...";
cd VyPRServer;
git clone git@github.com:pyvypr/VyPR.git;
cd ../SampleWebService;
git clone git@github.com:pyvypr/VyPR.git;
echo "All cloning is finished.  Generating verdict data.";

# move back to the root
cd ../;

tmux kill-server;

# new detached session for the verdict server
tmux new -d -s verdict_server;
tmux send-keys -t verdict_server 'cd VyPRServer/' Enter;
tmux send-keys -t verdict_server 'rm verdicts.db' Enter;
tmux send-keys -t verdict_server 'sqlite3 verdicts.db < verdict-schema.sql' Enter;
tmux send-keys -t verdict_server 'python run_service.py' Enter;
echo "Verdict server setup."

# delay a bit to give the server a chance to get started
sleep 3;

tmux list-sessions;

# new detached session for the monitored program
tmux new -d -s monitored;
tmux send-keys -t monitored 'cd SampleWebService/' Enter;
tmux send-keys -t monitored 'mkdir instrumentation_maps/ binding_spaces/ index_hash/' Enter;
tmux send-keys -t monitored 'python VyPR/instrument.py' Enter;
tmux send-keys -t monitored 'python run.py' Enter;
echo "Monitored service running."

# again, delay a bit to make sure the server is started
sleep 3;

tmux list-sessions;

echo "Sending requests to monitored service."

# verdict server and monitored service are now running in separate sessions
tmux new -d -s requests;
tmux send-keys -t requests 'curl http://0.0.0.0:8888/paths_branching_test/11/' Enter;
tmux send-keys -t requests 'curl http://0.0.0.0:8888/paths_branching_test/12/' Enter;
tmux send-keys -t requests 'curl http://0.0.0.0:8888/paths_branching_test/5/' Enter;
tmux send-keys -t requests 'curl http://0.0.0.0:8888/paths_branching_test/6/' Enter;

# give the server a chance to respond before we close this session
sleep 5;

tmux list-sessions;

# clean exit of all sessions
tmux kill-server;

#-------------------------------------------------------

# set up tutorial

git clone git@github.com:pyvypr/VyPRTutorial.git;
cd VyPRTutorial/;
git clone git@github.com:pyvypr/VyPRAnalysis.git;
git clone git@github.com:pyvypr/VyPR.git;
cd VyPRAnalysis/;
git clone git@github.com:pyvypr/VyPR.git;

cd ../../;
tmux new -d -s verdict_server;
tmux send-keys -t verdict_server 'cd VyPRServer/' Enter;
tmux send-keys -t verdict_server 'python run_service.py' Enter;

#tmux new -d -s tutorial;
#tmux send-keys -t tutorial 'cd VyPRTutorial/' Enter;
#tmux send-keys -t tutorial 'jupyter notebook --ip 0.0.0.0 --port 9003 --allow-root' Enter;

