test_dir = "/tmp/tpm_ex"

ESpec.configure fn(config) ->
  config.before fn(tags) ->
    File.mkdir_p(test_dir)
    {:shared, tags: tags}
  end

  config.finally fn(_shared) ->
    File.rm_rf(test_dir)
    :ok
  end
end
