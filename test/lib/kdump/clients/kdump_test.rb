require_relative "../../../test_helper"
require "kdump/clients/kdump"

Yast.import "CommandLine"
Yast.import "Kdump"

describe Yast::KdumpClient do
  subject { Yast::KdumpClient.new }

  before do
    allow(subject).to receive(:InstallPackages).and_return(true)
    allow(subject).to receive(:ReadDialog).and_return(true)

    subject.main
  end

  describe ".cmdKdumpStartup" do
    let(:alloc_mem_high) { "100" }
    let(:alloc_mem_low) { "50" }

    before do
      allow(Yast::Arch).to receive(:paravirtualized_xen_guest?).and_return(false)
    end

    context "when receiving the 'enable' option" do
      context "and using wrong inputs in alloc memory" do
        let(:options) { { "enable" => "", "alloc_mem" => "#{alloc_mem_low}:#{alloc_mem_high}" } }

        it "does not enable kdump and returns false" do
          expect(subject.cmdKdumpStartup(options)).to be false
        end
      end

      context "and using valid high and low inputs in alloc memory" do
        let(:options) { { "enable" => "", "alloc_mem" => "#{alloc_mem_low},#{alloc_mem_high}" } }

        it "sets the low and high values of Kdump allocated_memory " do
          subject.cmdKdumpStartup(options)
          expect(Yast::Kdump.allocated_memory).to eq(low: alloc_mem_low, high: alloc_mem_high)
          expect(Yast::Kdump.add_crashkernel_param).to be true
        end
      end

      context "and using a single input in alloc memory" do
        let(:options) { { "enable" => "", "alloc_mem" => alloc_mem_low.to_s } }

        it "enables only the low value of Kdump allocated_memory " do
          subject.cmdKdumpStartup(options)
          expect(Yast::Kdump.allocated_memory).to eq(low: alloc_mem_low, high: nil)
          expect(Yast::Kdump.add_crashkernel_param).to be true
        end
      end
    end

    context "when receiving the 'disable' option" do
      let(:options) { { "disable" => "", "alloc_mem" => alloc_mem_low.to_s } }

      it "sets kdump to be disabled" do
        subject.cmdKdumpStartup(options)
        expect(Yast::Kdump.add_crashkernel_param).to be false
      end
    end

    context "when receiving neither, 'enable' nor 'disable' option" do
      let(:options) { { "alloc_mem" => alloc_mem_low.to_s } }

      it "returns false" do
        expect(subject.cmdKdumpStartup(options)).to be false
      end
    end
  end
end
