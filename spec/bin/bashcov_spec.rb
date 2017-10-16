require 'tmpdir'
require 'json'
describe 'bin/bashcov' do

  let(:bashcov) do
    "#{__dir__}/../../#{self.class.top_level_description}"
  end

  let(:bash_script) {"test.sh"}
  let(:result_set){ JSON(File.read(result_set_json), symbolize_names: true)}

  let(:coverage_dir) {'coverage'}
  let(:result_set_json){"#{coverage_dir}/.resultset.json"}

  around(:each) do |example|
    Dir.mktmpdir do |path|
      Dir.chdir(path) do
        File.write(bash_script, "echo hello")
        example.call path
      end
    end
  end

  def run command
    raise "Failed to run #{command}" unless system "#{command} > /dev/null"
  end

  context '-a' do
    context 'no results recorded' do
      it 'creates a report' do
        run("#{bashcov} -a #{bash_script}")
        expect(File).to exist(coverage_dir)
      end
    end

    context 'results recorded' do
      it 'adds the results' do

        run("#{bashcov} -a -s #{bash_script}")

        second_bash_script = 'test2.sh'
        File.write(second_bash_script, 'echo "hello2"')
        run("#{bashcov} -a -s #{second_bash_script}")

        expect(result_set.size).to eq(2)

        first_run = result_set.values[0]
        second_run = result_set.values[1]
        expect(first_run[:coverage].size).to eq(1)
        expect(second_run[:coverage].size).to eq(2)
      end
    end
  end

  context '-a not supplied' do

    context 'not results recorded' do
      it 'generates a report' do
        run("#{bashcov} #{bash_script}")
        expect(File).to exist(coverage_dir)
      end
    end

    context 'results recorded' do
      it 'replaces the report' do
        run("#{bashcov} #{bash_script}")
        run("#{bashcov} #{bash_script}")

        result_set = JSON(File.read(result_set_json))
        expect(result_set.size).to eq(1)
      end
    end
  end
end