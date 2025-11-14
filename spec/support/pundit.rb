# Pundit RSpec support
# 為 policy spec 提供 permit 匹配器

RSpec::Matchers.define :permit do |action|
  match do |policy|
    policy.send("#{action}?")
  end

  failure_message do |policy|
    "expected #{policy.class} to permit #{action}"
  end

  failure_message_when_negated do |policy|
    "expected #{policy.class} not to permit #{action}"
  end
end

RSpec.configure do |config|
  config.include Module.new {
    def permit(action)
      RSpec::Matchers::BuiltIn::Match.new do |policy|
        policy.send("#{action}?")
      end
    end
  }, type: :policy
end
