require 'elasticsearch/persistence'
require_relative 'tag'

class TagIndex
  include Elasticsearch::Persistence::Repository
  include Elasticsearch::Persistence::Repository::DSL

  index_name 'github_tags'
  document_type 'tag'
  klass Tag

  settings number_of_shards: 1 do
    mapping do
      indexes :name
    end
  end

  def serialize(document)
    hash = document.to_hash.clone
    hash.to_hash
  end

  def deserialize(document)
    hash = document['_source']
    klass.new hash
  end

end
