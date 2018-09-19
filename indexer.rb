require 'elasticsearch/persistence'
require 'octokit'
require_relative 'repository_index.rb'
require_relative   'tag_index.rb'

ES_ENDPOINT="https://a96fa286204444a3a91c8327c5867a85.us-central1.gcp.cloud.es.io:9243"
ORG_NAME='elastic'
client = Elasticsearch::Client.new(url: ES_ENDPOINT, user: 'elastic', password: ENV['ES_CLOUD_PASSWORD'], log: false)

repo_index = RepositoryIndex.new(client: client)
tag_index = TagIndex.new(client: client)

# Create indices if they don't exist
repo_index.create_index!
tag_index.create_index!

## Retrive GitHub Repos sorted by updated_at
octokit_client = Octokit::Client.new(:access_token => ENV['GITHUB_TOKEN'])
octokit_repos = octokit_client.org_repositories(ORG_NAME, :sort => :created).sort_by { |r| r.updated_at  }
last_update_repo = octokit_repos[0]
last_remote_update = DateTime.strptime(last_update_repo.updated_at.iso8601)

## Retrieve last updated repository we have on record (if any)
results = repo_index.search(query: { match_all: {} }, sort: [{updated_at: {order: 'desc'}}], size: 1)
if results.total > 0
  last_local_update = DateTime.strptime(results.first.attributes["updated_at"])
  ## Do we already have the latest updated repo?
  if last_local_update >= last_remote_update
    puts "We already have the latest!"
    return
  end
end

## Index each repo with each tags: there's definitely room for optimization using bulk update
octokit_repos.each_with_index do |octokit_repo|
  puts "Indexing Repository #{octokit_repo.name}"
  repo = Repository.new(octokit_repo)
  repo_index.save(repo)

  octokit_tags = octokit_client.tags(octokit_repo.id)
  octokit_tags.each do |octokit_tag|
    tag = Tag.new(repo, octokit_tag.to_hash)
    tag_index.save(tag)
  end
end

puts "Refreshing indices"
repo_index.refresh_index!
tag_index.refresh_index!

### Optimziation Ideas:
# 1- Use bulk operations (most important)
# 2- Do not retrieve/index tags if updated_at matches what we have on record
# 3- Use child/parent relation (join field)
# 4- Specify mapping types to match expected search experience, don't rely on inference for all fields
