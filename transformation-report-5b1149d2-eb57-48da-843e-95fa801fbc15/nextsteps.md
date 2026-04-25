# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Example:

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Ensure there are no warnings that could indicate deprecated APIs or compatibility issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Check for Runtime-Only Issues

Some issues do not surface at build time. Pay attention to the following areas that commonly differ between .NET Framework and modern .NET:

- **`System.Configuration`**: `ConfigurationManager` requires the `System.Configuration.ConfigurationManager` NuGet package.
- **WCF or Remoting**: These are not fully supported on cross-platform .NET. Verify any communication layers still function.
- **Registry Access**: `Microsoft.Win32.Registry` is Windows-only. If cross-platform support is required, this must be replaced.
- **`AppDomain`**: Some `AppDomain` APIs are no-ops or throw `PlatformNotSupportedException` on modern .NET.
- **Reflection and serialization**: Behavior differences may exist, particularly with `BinaryFormatter`, which is disabled by default in modern .NET.

## 5. Validate NuGet Package Compatibility

Review all NuGet dependencies and confirm they target .NET Standard 2.0+ or the specific .NET version you are using. You can inspect this with:

```bash
dotnet list package
```

Flag any packages that are outdated or that reference only `net4x` targets, as they may cause runtime issues even if the build succeeds.

## 6. Test on Target Operating Systems

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to catch platform-specific issues that would not appear in a Windows-only build.

## 7. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment (no .NET runtime required on the target machine):

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained true --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier for your target platform (e.g., `linux-x64`, `osx-x64`).

## 8. Review Output Artifacts

Inspect the contents of the `./publish` directory to confirm all expected assemblies, configuration files, and static assets are present before deploying to the target environment.