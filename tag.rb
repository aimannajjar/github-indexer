class Tag
  attr_reader :attributes

  def initialize(repo, attributes={})
    attributes[:repo_id] = repo.attributes["id"]
    attributes[:repo_name] = repo.attributes["name"]
    @attributes = attributes
  end

  def to_hash
    @attributes
  end
end
