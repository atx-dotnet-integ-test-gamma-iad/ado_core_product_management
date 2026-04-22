# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If it is still referencing a Windows-only TFM such as `net472` or `net48`, update it accordingly.

---

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate compatibility issues, deprecated APIs, or platform-specific code paths that were silently retained.

---

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior has not been broken during the migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by behavioral differences in the new runtime or by platform-specific assumptions in the test code itself.

---

## 4. Check for Platform-Specific API Usage

Even without build errors, some APIs may have been carried over that are Windows-specific or otherwise not cross-platform. Use the .NET Compatibility Analyzer to surface these at build time by adding the following to `AdoCore.csproj`:

```xml
<PropertyGroup>
  <PlatformTarget>AnyCPU</PlatformTarget>
  <Nullable>enable</Nullable>
  <AnalysisMode>All</AnalysisMode>
</PropertyGroup>
```

Run the build again and address any new analyzer warnings, particularly those prefixed with `CA1416` (platform compatibility).

---

## 5. Validate Runtime Behavior on Target Platforms

Run the application on each platform you intend to support (e.g., Linux, macOS, Windows) to confirm there are no runtime exceptions caused by platform-specific behavior that was not caught at compile time. Pay particular attention to:

- File path separators (`/` vs `\`)
- Registry access (not available on non-Windows)
- Windows-specific authentication or security APIs
- COM interop usage

---

## 6. Review NuGet Package Compatibility

Check that all NuGet dependencies support the target framework. Run the following to list packages and their resolved versions:

```bash
dotnet list package
```

For any packages that do not support the new TFM, look for updated versions or cross-platform alternatives on [nuget.org](https://www.nuget.org).

---

## 7. Publish the Application

Once validation is complete, publish the application for your target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate runtime identifier (RID) for your deployment target. A full list of RIDs is available in the [.NET RID Catalog](https://learn.microsoft.com/en-us/dotnet/core/rid-catalog).