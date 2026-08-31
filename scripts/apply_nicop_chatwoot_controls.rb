require "json"

account = Account.find_by(name: "CRM Komodo") || Account.find(1)

labels = [
  ["agente_off", "agente_off", "#FF0000"],
  ["campania_mantenimiento", "Campaña Marzo 2026", "#839D23"],
  ["camp_test", "", "#A80943"],
  ["cotizado", "Cotizado Llantas", "#AC3F6F"],
  ["inbound", "primer mensaje", "#5ADB58"],
  ["leo_desactivado", "LEO_desactivado", "#DE1043"],
  ["vendida", "Venta de llantas", "#3AD813"]
]

labels.each do |title, description, color|
  label = Label.find_or_initialize_by(account_id: account.id, title: title)
  label.description = description
  label.color = color
  label.save!
end

attribute = CustomAttributeDefinition.find_or_initialize_by(
  account_id: account.id,
  attribute_key: "agent_status",
  attribute_model: "conversation_attribute"
)
attribute.attribute_display_name = "Koko"
attribute.attribute_display_type = "list"
attribute.attribute_values = ["ON", "OFF"]
attribute.save!

bot = AgentBot.find_by(name: "Koko")
if bot
  Inbox.where(
    account_id: account.id,
    name: ["NICOP USA WhatsApp", "NICOP WebPage", "Oncoorchbot"]
  ).find_each do |inbox|
    AgentBotInbox.find_or_create_by!(agent_bot_id: bot.id, inbox_id: inbox.id)
  end
end

puts JSON.pretty_generate(
  account: { id: account.id, name: account.name },
  labels: Label.where(account_id: account.id).order(:title).pluck(:title),
  custom_attributes: CustomAttributeDefinition.where(account_id: account.id).order(:attribute_key).pluck(:attribute_key),
  bot: bot && { id: bot.id, name: bot.name }
)
