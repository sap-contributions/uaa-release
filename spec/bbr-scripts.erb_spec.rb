require 'rspec'
require 'yaml'
require 'bosh/template/evaluation_context'
require 'spec_helper'

describe 'bosh backup and restore script' do
  let(:properties) {
    {
      'properties' => {
        'uaadb' => {
          'address' => '127.0.0.1',
          'port' => 5432,
          'scheme' => 'postgres',
          'databases' => [{'name' => 'uaa_db_name', 'tag' => 'uaa'}],
          'roles' => [{'name' => 'admin', 'password' => 'example', 'tag' => 'admin'}]
        }
      }
    }
  }
  let(:generated_script) {
    binding = Bosh::Template::EvaluationContext.new(properties).get_binding
    generated_script = ERB.new(File.read(script)).result(binding)
  }

  describe 'b-backup.erb' do
    let(:script) { "#{__dir__}/../jobs/uaa/templates/b-backup.erb" }

    it 'should run pg_dump' do
      expect(generated_script).to include('export PGPASSWORD="example"')
      expect(generated_script).to include('/var/vcap/packages/postgres-9.4/bin/pg_dump')
      expect(generated_script).to include('--user="admin"')
      expect(generated_script).to include('--host="127.0.0.1"')
      expect(generated_script).to include('--port="5432"')
      expect(generated_script).to include('"uaa_db_name"')
    end

    describe 'when uaadb.address is not set' do
      it 'should not pg_dump' do
        properties['properties']['uaadb']['address'] = nil
        expect(generated_script).to_not include('pg_dump')
      end
    end

    describe 'when uaadb.scheme is not postgres' do
      it 'should not pg_dump' do
        properties['properties']['uaadb']['scheme'] = 'not-postgres'
        expect(generated_script).to_not include('pg_dump')
      end
    end
  end

  describe 'b-restore.erb' do
    let(:script) { "#{__dir__}/../jobs/uaa/templates/b-restore.erb" }

    it 'should run pg_restore' do
      expect(generated_script).to include('export PGPASSWORD="example"')
      expect(generated_script).to include('/var/vcap/packages/postgres-9.4/bin/pg_restore')
      expect(generated_script).to include('--user="admin"')
      expect(generated_script).to include('--host="127.0.0.1"')
      expect(generated_script).to include('--port="5432"')
      expect(generated_script).to include('--dbname "uaa_db_name"')
    end

    describe 'when uaadb.address is not set' do
      it 'should not pg_restore' do
        properties['properties']['uaadb']['address'] = nil
        expect(generated_script).to_not include('pg_restore')
      end
    end

    describe 'when uaadb.scheme is not postgres' do
      it 'should not pg_dump' do
        properties['properties']['uaadb']['scheme'] = 'not-postgres'
        expect(generated_script).to_not include('pg_restore')
      end
    end
  end
end
