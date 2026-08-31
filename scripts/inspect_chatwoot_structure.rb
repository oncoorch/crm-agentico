require "json"

account = Account.first
user = User.where(
  "lower(name) like ? or lower(email) like ?",
  "%jaqueline%",
  "%jreinoso%"
).first

redact = lambda do |value|
  value.to_s.gsub(/[A-Za-z0-9_\-]{16,}/, "[redacted]")
end

data = {
  account: account && { id: account.id, name: account.name },
  user: user && {
    id: user.id,
    name: user.name,
    email: user.email,
    role: user.role,
    confirmed: user.confirmed?
  },
  account_user: user && AccountUser.where(user_id: user.id).map do |au|
    {
      account_id: au.account_id,
      role: au.role,
      availability_status: au.availability_status
    }
  end,
  labels: Label.where(account_id: account&.id).order(:title).map do |label|
    {
      title: label.title,
      description: label.description,
      color: label.color
    }
  end,
  custom_attributes: CustomAttributeDefinition.where(account_id: account&.id).order(:attribute_key).map do |attribute|
    {
      attribute_key: attribute.attribute_key,
      attribute_display_name: attribute.attribute_display_name,
      attribute_display_type: attribute.attribute_display_type,
      attribute_model: attribute.attribute_model,
      attribute_values: attribute.attribute_values
    }
  end,
  agent_bots: AgentBot.order(:name).map do |bot|
    {
      id: bot.id,
      name: bot.name,
      description: redact.call(bot.description),
      outgoing_url: redact.call(bot.outgoing_url)
    }
  end,
  inboxes: Inbox.where(account_id: account&.id).order(:name).map do |inbox|
    {
      id: inbox.id,
      name: inbox.name,
      channel_type: inbox.channel_type
    }
  end
}

puts JSON.pretty_generate(data)
