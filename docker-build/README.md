# Docker images build

There you can find gitlab pipeline for docker build. This pipeline executes on already registered gitlab-runner(linux machine) with shell environment, 
because docker layers cache mechanism doest not with gitlab shared runners (docker in docker builds) => https://about.gitlab.com/blog/2016/05/23/gitlab-container-registry/