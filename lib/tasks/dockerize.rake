DOCKER_REPO = "brunom/rest-ftp-daemon"

desc "Build docker image from latest tag"

task :dockerize => [] do
  version     =  `git describe --tags`.strip

  puts
  puts "* build [#{version}]"
  sh "docker build . -t '#{DOCKER_REPO}:#{version}' -t '#{DOCKER_REPO}:latest'"

  puts
  puts "* push to: [#{DOCKER_REPO}]"
    sh "docker push #{DOCKER_REPO}:#{version}"
    sh "docker push #{DOCKER_REPO}:latest"

  puts
end
