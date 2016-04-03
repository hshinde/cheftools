execute :create_postgis_template do
	user "postgres"
	command "createdb -E UTF8 --locale=en_US.utf8 -T template0 #{node[:postgis][:template_name]}"
	not_if "psql -qAt --list | grep '^#{node[:postgis][:template_name]}\|'", :user => 'postgres'
	action :run
end