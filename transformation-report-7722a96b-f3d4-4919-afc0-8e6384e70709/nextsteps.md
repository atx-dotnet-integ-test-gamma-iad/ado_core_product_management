# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

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

Ensure there are no warnings that could indicate compatibility issues, such as deprecated APIs or platform-specific code paths.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality is intact:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Check for Platform-Specific API Usage

Even without build errors, some APIs may have been removed or behave differently in cross-platform .NET. Review the code for usage of the following:

- `System.Web` namespace (not available outside of ASP.NET Core)
- Windows Registry access (`Microsoft.Win32.Registry`)
- `AppDomain` members that are no longer supported
- COM interop or P/Invoke calls that are Windows-specific

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` package to identify remaining compatibility concerns.

## 5. Validate NuGet Package Compatibility

Check that all referenced NuGet packages target `netstandard2.0`, `netstandard2.1`, or the specific .NET version you are targeting. Packages that only target `net45` or similar legacy monikers may still resolve but could cause runtime issues.

```bash
dotnet list package --outdated
```

Update any outdated packages where applicable.

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear at compile time.

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

**Framework-dependent (requires .NET runtime installed on target machine):**
```bash
dotnet publish -c Release -o ./publish
```

**Self-contained (bundles the runtime):**
```bash
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) as needed.

## 8. Review Output Artifacts

Inspect the `./publish` directory to confirm all expected assemblies, configuration files, and assets are present before deploying to the target environment.