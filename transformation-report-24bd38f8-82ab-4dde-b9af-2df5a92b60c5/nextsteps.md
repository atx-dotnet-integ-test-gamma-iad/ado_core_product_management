# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Ensure this is consistent with any dependent or consuming projects in the solution.

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

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they do not block the build.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that runtime behavior has not changed during the migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Check for Runtime Compatibility Issues

Even with a clean build, certain APIs behave differently on cross-platform .NET. Pay attention to the following areas:

- **Windows-specific APIs**: Any usage of `System.Windows.Forms`, `System.Drawing`, or registry access may require the `windows` platform target (e.g., `net8.0-windows`) or a compatibility NuGet package.
- **Configuration**: `System.Configuration.ConfigurationManager` requires the `System.Configuration.ConfigurationManager` NuGet package if used.
- **Reflection and serialization**: Some patterns that worked under .NET Framework may behave differently under the new runtime.

## 5. Review NuGet Package Versions

Check that all NuGet packages referenced in `AdoCore.csproj` are up to date and compatible with your target framework. You can use the following command to identify outdated packages:

```bash
dotnet list package --outdated
```

Update packages where appropriate, and verify there are no known compatibility issues with the target framework version.

## 6. Test on Target Platforms

Since the goal of the migration is cross-platform support, run and validate the application on each intended operating system (e.g., Windows, Linux, macOS) to surface any platform-specific runtime issues.

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier for your environment (e.g., `win-x64`, `osx-x64`). Use `--self-contained false` if the target machine has the .NET runtime installed.

## 8. Verify Published Output

After publishing, navigate to the output directory (typically `bin/Release/net8.0/<rid>/publish/`) and confirm all expected files are present, including configuration files, static assets, and dependencies.