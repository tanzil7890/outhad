# frozen_string_literal: true

RSpec.describe Outhad::Integrations do
  describe "::ENABLED_SOURCES" do
    let(:enabled_sources) { Outhad::Integrations::ENABLED_SOURCES }
    let(:enabled_destinations) { Outhad::Integrations::ENABLED_DESTINATIONS }

    context "when meta.json name is valid" do
      it "creates valid class object for source connector" do
        enabled_sources.each do |source|
          class_name = "Outhad::Integrations::Source::#{source}::Client"
          meta_json_name = Object.const_get(class_name).new.send("meta_data")[:data][:name]
          expect(meta_json_name).to eq(source)
          expect(Object.const_defined?("Outhad::Integrations::Source::#{meta_json_name}::Client")).to eq(true)
        end
      end

      it "creates valid class object for destination connector" do
        enabled_destinations.each do |destination|
          class_name = "Outhad::Integrations::Destination::#{destination}::Client"
          meta_json_name = Object.const_get(class_name).new.send("meta_data")[:data][:name]
          expect(meta_json_name).to eq(destination)
          expect(Object.const_defined?("Outhad::Integrations::Destination::#{meta_json_name}::Client")).to eq(true)
        end
      end
    end

    context "when meta.json is created" do
      it "include valid fields" do
        enabled_destinations.each do |destination|
          class_name = "Outhad::Integrations::Destination::#{destination}::Client"
          meta_json_keys = Object.const_get(class_name).new.send("meta_data")[:data].keys

          expect(meta_json_keys).to include(:name, :title, :connector_type, :category,
                                            :documentation_url, :github_issue_label, :icon,
                                            :license, :release_stage, :support_level, :tags)
        end

        enabled_sources.each do |source|
          class_name = "Outhad::Integrations::Source::#{source}::Client"
          meta_json_keys = Object.const_get(class_name).new.send("meta_data")[:data].keys

          expect(meta_json_keys).to include(:name, :title, :connector_type, :category,
                                            :documentation_url, :github_issue_label, :icon,
                                            :license, :release_stage, :support_level, :tags)
        end
      end
    end

    context "when connector is created" do
      it "include a icon.svg in connector folder" do
        enabled_destinations.each do |destination|
          class_name = "Outhad::Integrations::Destination::#{destination}::Client"
          icon_path = "#{connector_class_path(class_name)}/icon.svg"

          expect(File.exist?(icon_path)).to be_truthy
        end

        enabled_sources.each do |source|
          class_name = "Outhad::Integrations::Source::#{source}::Client"
          icon_path = "#{connector_class_path(class_name)}/icon.svg"

          expect(File.exist?(icon_path)).to be_truthy
        end
      end
    end
  end

  private

  def connector_class_path(class_name)
    path = Object.const_source_location(class_name)[0]
    File.dirname(path)
  end
end
