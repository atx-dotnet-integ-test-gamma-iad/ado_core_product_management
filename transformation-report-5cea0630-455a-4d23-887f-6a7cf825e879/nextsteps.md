# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). For example:

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

Ensure there are no warnings that could indicate deprecated APIs or compatibility issues that were not surfaced as errors.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Check for Platform-Specific API Usage

Even without build errors, some APIs may have been replaced with stubs or may throw `PlatformNotSupportedException` at runtime on non-Windows platforms. Review usage of the following common areas:

- `System.Drawing` (replaced by packages such as `System.Drawing.Common`, which has platform restrictions)
- `Microsoft.Win32` registry APIs
- `System.Security.Permissions`
- WCF server-side components
- `AppDomain.CreateDomain`

Run the application on each target platform (Windows, Linux, macOS) if cross-platform support is a requirement.

## 5. Validate NuGet Package Compatibility

Check that all NuGet dependencies reference packages that support your target framework. Run the following to identify any potential issues:

```bash
dotnet list package --outdated
dotnet list package --vulnerable
```

Update any outdated or vulnerable packages as appropriate.

## 6. Smoke Test Core Functionality

Manually exercise the primary entry points and critical code paths of the application. Pay particular attention to:

- Database connections and ADO.NET operations (given the `AdoCore` project name suggests data access usage)
- Configuration loading (note that `System.Configuration.ConfigurationManager` requires the `System.Configuration.ConfigurationManager` NuGet package in .NET Core and later)
- Any file I/O paths that may have been written with Windows-style path separators

## 7. Review Output Artifacts

Confirm the build output is placed in the expected directory and that all required files (configuration files, native dependencies, etc.) are present:

```bash
dotnet publish --configuration Release --output ./publish
```

Inspect the `./publish` directory to ensure completeness before deployment.

## 8. Deploy

Once validation is complete, copy the published output to the target environment and run the application. If the application is a console app or service, execute it directly:

```bash
dotnet AdoCore.dll
```

If it is a library, confirm that consuming applications reference it correctly and rebuild those projects against the new binary.