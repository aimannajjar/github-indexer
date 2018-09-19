require 'elasticsearch/persistence'
require_relative 'repository'

class RepositoryIndex
  include Elasticsearch::Persistence::Repository
  include Elasticsearch::Persistence::Repository::DSL

  index_name 'github_repositories'
  document_type 'repository'
  klass Repository

  settings number_of_shards: 1 do
    mapping do
      indexes :name
      indexes :html_url
      indexes :description
      indexes :url
      indexes :pushed_at, type: :date, index: false
      indexes :created_at, type: :date, index: false
      indexes :updated_at, type: :date, index: false
    end
  end

  def serialize(document)
    hash = document.to_hash
    hash[:updated_at] = hash[:updated_at].iso8601()
    hash[:created_at] = hash[:created_at].iso8601()
    hash[:pushed_at] = hash[:pushed_at].iso8601()
    hash.to_hash
  end

  def deserialize(document)
    hash = document['_source']
    klass.new hash
  end

end
