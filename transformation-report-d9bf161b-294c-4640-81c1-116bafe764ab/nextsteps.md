# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

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

Ensure there are no warnings that could indicate deprecated APIs or packages that may cause runtime issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify functional correctness after migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

## 4. Check for Runtime Compatibility Issues

Even with a clean build, certain APIs behave differently on cross-platform .NET compared to .NET Framework. Pay attention to the following areas:

- **File paths**: Ensure no hardcoded Windows-style paths (e.g., `C:\`) exist in the codebase. Use `Path.Combine` and `Path.DirectorySeparatorChar` where appropriate.
- **Registry access**: `Microsoft.Win32.Registry` is not available on Linux/macOS. Remove or conditionally compile any registry-dependent code.
- **Windows-only APIs**: Review any P/Invoke calls or use of `System.Windows.Forms` / `System.Drawing` that may not be supported cross-platform.
- **Configuration**: If the project previously used `System.Configuration.ConfigurationManager`, confirm the `System.Configuration.ConfigurationManager` NuGet package has been added and that `app.config` files are handled correctly.

## 5. Validate NuGet Package Compatibility

Check that all NuGet packages referenced in `AdoCore.csproj` are compatible with the target framework. You can use the following command to identify outdated or incompatible packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer versions compatible with your target framework.

## 6. Test on Target Platform

If the goal is cross-platform support, run the application on each intended operating system (Windows, Linux, macOS) to catch any platform-specific runtime exceptions that would not appear during a build.

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

**Framework-dependent (requires .NET runtime on the host):**
```bash
dotnet publish -c Release -o ./publish
```

**Self-contained (bundles the runtime):**
```bash
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) as needed.

## 8. Review Output and Configuration Files

After publishing, verify that all required configuration files (e.g., `appsettings.json`, `app.config`) and any static assets are present in the publish output directory and are correctly referenced by the application at runtime.