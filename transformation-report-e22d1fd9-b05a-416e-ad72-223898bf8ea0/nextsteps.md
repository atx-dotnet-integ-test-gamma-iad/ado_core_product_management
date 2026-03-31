# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Example:

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
  </PropertyGroup>
</Project>
```

## 2. Restore and Build

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Ensure there are no warnings that could indicate deprecated APIs or compatibility issues that were not surfaced as errors.

## 3. Review NuGet Package Compatibility

Check that all NuGet packages referenced in `AdoCore.csproj` are compatible with your target framework. Run:

```bash
dotnet list package --outdated
```

Update any outdated packages that have stable releases targeting your framework version.

## 4. Run Existing Tests

If a test project exists in the solution, execute the test suite to verify runtime behavior is consistent with the original project:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any test failures carefully, as they may indicate behavioral differences between the legacy .NET Framework APIs and the cross-platform .NET equivalents.

## 5. Check for Platform-Specific API Usage

Even without build errors, some APIs may have been replaced with cross-platform alternatives that behave differently at runtime. Review usages of the following common areas:

- **Registry access** (`Microsoft.Win32.Registry`) — not available on Linux/macOS.
- **Windows Communication Foundation (WCF)** — client-side is supported via `System.ServiceModel`, but server-side is not.
- **`System.Drawing`** — requires the `System.Drawing.Common` package and may have OS-specific limitations.
- **`AppDomain`** — some members are not supported on .NET Core and later.

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify any remaining concerns.

## 6. Test on Target Operating Systems

If cross-platform support is a goal, run and test the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear during a Windows-only build.

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once testing is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
# Framework-dependent deployment
dotnet publish --configuration Release --output ./publish

# Self-contained deployment (example for Linux x64)
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` directory to confirm all required files are present before deploying to the target environment.