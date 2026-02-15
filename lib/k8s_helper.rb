def kubeconfig
  return ENV["KUBECONFIG"] if ENV["KUBECONFIG"]
  if %w[miceportal-production miceportal-beta].include?(k8s_namespace)
    "/Users/michaeldeimel/.kube/boreus-miceportal-production.yml"
  else
    "/Users/michaeldeimel/.kube/boreus-miceportal-stage.yml"
  end
end

def checking_namespace(programm)
  if @namespace.nil?
    puts "Usage: #{programm} <namespace>"
    exit 1
  end
end

def alias_namespace(namespace)
  {
    prod: 'miceportal-production',
    production: 'miceportal-production',
    beta: 'miceportal-beta',
    alpha: 'miceportal-alpha',
  }[namespace.to_sym] || namespace
end

def k8s_namespace
  alias_namespace(@namespace)
end

def run_kubectl(cmd)
  cmd = "KUBECONFIG=#{kubeconfig} kubectl #{cmd} -n #{k8s_namespace}"
  puts cmd
  puts `#{cmd}`.strip
end
