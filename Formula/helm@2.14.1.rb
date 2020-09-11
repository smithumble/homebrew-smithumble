class HelmAT2141 < Formula
  desc "The Kubernetes package manager"
  homepage "https://helm.sh/"
  url "https://github.com/helm/helm.git",
      :tag      => "v2.14.1",
      :revision => "5270352a09c7e8b6e8c9593002a73535276507c0"
  head "https://github.com/helm/helm.git"

  depends_on "glide" => :build
  depends_on "go" => :build

  # Fix for vbom.ml bootstrap
  # [WARN]	Unable to checkout vbom.ml/util
  # [ERROR]	Update failed for vbom.ml/util: Cannot detect VCS
  # [ERROR]	Failed to install: Cannot detect VCS
  # Makefile:120: recipe for target 'bootstrap' failed
  # https://github.com/helm/helm/pull/2345/commits/b18625092e2a225ebd75d30ca98683a6418b5cd1
  patch :DATA

  def install
    ENV["GOPATH"] = buildpath
    ENV["GLIDE_HOME"] = HOMEBREW_CACHE/"glide_home/#{name}"
    ENV.prepend_create_path "PATH", buildpath/"bin"
    ENV["TARGETS"] = "darwin/amd64"
    dir = buildpath/"src/k8s.io/helm"
    dir.install buildpath.children - [buildpath/".brew_home"]

    cd dir do

      system "make", "bootstrap"
      system "make", "build"

      bin.install "bin/helm"
      bin.install "bin/tiller"
      man1.install Dir["docs/man/man1/*"]

      output = Utils.popen_read("SHELL=bash #{bin}/helm completion bash")
      (bash_completion/"helm").write output

      output = Utils.popen_read("SHELL=zsh #{bin}/helm completion zsh")
      (zsh_completion/"_helm").write output

      prefix.install_metafiles
    end
  end

  test do
    system "#{bin}/helm", "create", "foo"
    assert File.directory? "#{testpath}/foo/charts"

    version_output = shell_output("#{bin}/helm version --client 2>&1")
    assert_match stable.instance_variable_get(:@resource).instance_variable_get(:@specs)[:revision], version_output if build.stable?
  end
end

__END__
diff --git a/glide.lock b/glide.lock
index 4f031a5..698ca51 100644
--- a/glide.lock
+++ b/glide.lock
@@ -818,6 +818,8 @@ imports:
   version: fd68e9863619f6ec2fdd8625fe1f02e7c877e480
 - name: vbom.ml/util
   version: db5cfe13f5cc80a4990d98e2e1b0707a4d1a5394
+  repo: https://github.com/fvbommel/util.git
+  vcs: git
   subpackages:
   - sortorder
 testImports:
diff --git a/glide.yaml b/glide.yaml
index c9ac54b..b6172c9 100644
--- a/glide.yaml
+++ b/glide.yaml
@@ -67,6 +67,9 @@ import:
   - package: github.com/jmoiron/sqlx
     version: ^1.2.0
   - package: github.com/rubenv/sql-migrate
+  - package: vbom.ml/util
+    repo: https://github.com/fvbommel/util.git
+    vcs: git
 
 testImports:
   - package: github.com/stretchr/testify
